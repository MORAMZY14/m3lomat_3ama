"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateQuestions = exports.resetUsedQuestions = exports.challenge = exports.createChallenge = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
const openai_1 = __importDefault(require("openai"));
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const region = "us-central1";
const openAiApiKey = (0, params_1.defineSecret)("OPENAI_API_KEY");
const openAiModel = (0, params_1.defineString)("OPENAI_MODEL", { default: "gpt-5.6-luna" });
const publicBaseUrl = (0, params_1.defineString)("PUBLIC_BASE_URL", { default: "" });
const questionSlots = [
    { points: 200, teamIndex: 0, difficulty: "easy" },
    { points: 200, teamIndex: 1, difficulty: "easy" },
    { points: 400, teamIndex: 0, difficulty: "medium" },
    { points: 400, teamIndex: 1, difficulty: "medium" },
    { points: 600, teamIndex: 0, difficulty: "hard" },
    { points: 600, teamIndex: 1, difficulty: "hard" },
];
exports.createChallenge = (0, https_1.onCall)({
    region,
    timeoutSeconds: 30,
    memory: "256MiB",
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Firebase Authentication is required.");
    }
    const data = asRecord(request.data);
    const content = requiredString(data.content, "content", 2000);
    const type = optionalString(data.type, 20) ?? "text";
    if (!["text", "image", "audio"].includes(type)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid challenge type.");
    }
    const expiresAt = firestore_1.Timestamp.fromMillis(Date.now() + 4 * 60 * 60 * 1000);
    const ref = await db.collection("challenges").add({
        type: type,
        content,
        imageUrl: optionalString(data.imageUrl, 2000),
        audioUrl: optionalString(data.audioUrl, 2000),
        metadata: isPlainObject(data.metadata) ? data.metadata : null,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        expiresAt,
        createdBy: request.auth.uid,
    });
    return {
        id: ref.id,
        url: buildChallengeUrl(ref.id),
    };
});
exports.challenge = (0, https_1.onRequest)({
    region,
    timeoutSeconds: 30,
    memory: "256MiB",
}, async (request, response) => {
    response.set("Cache-Control", "private, no-store, max-age=0");
    response.set("X-Content-Type-Options", "nosniff");
    response.set("Content-Security-Policy", "default-src 'none'; img-src https: data:; media-src https:; style-src 'unsafe-inline';");
    const id = typeof request.query.id === "string" ? request.query.id.trim() : "";
    if (!id || id.length > 160) {
        response.status(400).send(renderError("رابط التحدي غير صحيح"));
        return;
    }
    const snapshot = await db.collection("challenges").doc(id).get();
    if (!snapshot.exists) {
        response.status(404).send(renderError("التحدي غير موجود"));
        return;
    }
    const data = snapshot.data() ?? {};
    const expiresAt = data.expiresAt instanceof firestore_1.Timestamp ? data.expiresAt.toMillis() : 0;
    if (expiresAt && expiresAt < Date.now()) {
        response.status(410).send(renderError("انتهت صلاحية التحدي"));
        return;
    }
    response.status(200).type("html").send(renderChallenge(data));
});
exports.resetUsedQuestions = (0, https_1.onCall)({
    region,
    timeoutSeconds: 120,
    memory: "256MiB",
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in with an admin account first.");
    }
    if (request.auth.token.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "This account does not have the admin custom claim.");
    }
    let reset = 0;
    for (const collectionName of ["questions", "audioQuestions"]) {
        while (true) {
            const snapshot = await db.collection(collectionName).where("used", "==", true).limit(400).get();
            if (snapshot.empty)
                break;
            const batch = db.batch();
            snapshot.docs.forEach((doc) => {
                batch.update(doc.ref, { used: false, usedAt: null });
                reset += 1;
            });
            await batch.commit();
        }
    }
    return { reset };
});
exports.generateQuestions = (0, https_1.onCall)({
    region,
    timeoutSeconds: 180,
    memory: "512MiB",
    secrets: [openAiApiKey],
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in with an admin account first.");
    }
    if (request.auth.token.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "This account does not have the admin custom claim.");
    }
    const data = asRecord(request.data);
    const categoryId = requiredString(data.categoryId, "categoryId", 160);
    const sets = clampInteger(data.sets, 1, 5, 1);
    const language = optionalString(data.language, 30) ?? "ar-EG";
    const categorySnapshot = await db.collection("categories").doc(categoryId).get();
    if (!categorySnapshot.exists) {
        throw new https_1.HttpsError("not-found", "Category not found.");
    }
    const category = categorySnapshot.data() ?? {};
    const categoryName = String(category.arabicName ?? category.name ?? "").trim();
    if (!categoryName) {
        throw new https_1.HttpsError("failed-precondition", "The category has no name.");
    }
    const total = sets * questionSlots.length;
    const model = openAiModel.value();
    const client = new openai_1.default({ apiKey: openAiApiKey.value() });
    const response = await client.responses.create({
        model,
        store: false,
        input: [
            {
                role: "developer",
                content: "You create accurate team trivia questions. Return only the structured output. " +
                    "Questions must be concise, unambiguous, culturally appropriate, and factually correct. " +
                    "Avoid duplicate questions, multiple choice, hints, trick wording, current/latest facts, politics, sexual content, and unsafe content.",
            },
            {
                role: "user",
                content: buildGenerationPrompt(categoryName, total, language),
            },
        ],
        stream: false,
        text: {
            format: {
                type: "json_schema",
                name: "ma3lomat_questions",
                strict: true,
                schema: {
                    type: "object",
                    additionalProperties: false,
                    properties: {
                        questions: {
                            type: "array",
                            minItems: total,
                            maxItems: total,
                            items: {
                                type: "object",
                                additionalProperties: false,
                                properties: {
                                    question: { type: "string" },
                                    answer: { type: "string" },
                                    fact: { type: "string" },
                                    acceptedAnswers: {
                                        type: "array",
                                        items: { type: "string" },
                                    },
                                    answerRule: { type: "string" },
                                },
                                required: ["question", "answer", "fact", "acceptedAnswers", "answerRule"],
                            },
                        },
                    },
                    required: ["questions"],
                },
            },
        },
    });
    if (!response.output_text) {
        throw new https_1.HttpsError("internal", "OpenAI returned an empty response.");
    }
    let parsed;
    try {
        parsed = JSON.parse(response.output_text);
    }
    catch {
        throw new https_1.HttpsError("internal", "OpenAI returned invalid JSON.");
    }
    if (!Array.isArray(parsed.questions) || parsed.questions.length !== total) {
        throw new https_1.HttpsError("internal", `Expected ${total} questions from OpenAI.`);
    }
    const batch = db.batch();
    parsed.questions.forEach((question, index) => {
        validateGeneratedQuestion(question);
        const slot = questionSlots[index % questionSlots.length];
        const ref = db.collection("questions").doc();
        batch.set(ref, {
            categoryId,
            categoryName,
            points: slot.points,
            teamIndex: slot.teamIndex,
            difficulty: slot.difficulty,
            question: question.question.trim(),
            answer: question.answer.trim(),
            fact: question.fact.trim(),
            acceptedAnswers: question.acceptedAnswers.map((answer) => answer.trim()).filter(Boolean),
            answerRule: question.answerRule.trim(),
            imageUrl: null,
            questionImageUrl: null,
            used: false,
            usedAt: null,
            source: "openai",
            sourceModel: model,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: request.auth?.uid,
        });
    });
    await batch.commit();
    return { created: total, model };
});
function buildGenerationPrompt(categoryName, total, language) {
    const repeatedSlots = Array.from({ length: total }, (_, index) => {
        const slot = questionSlots[index % questionSlots.length];
        return `${index + 1}. ${slot.difficulty}, ${slot.points} points, team ${slot.teamIndex + 1}`;
    }).join("\n");
    return `Generate exactly ${total} unique trivia questions for the category "${categoryName}".\n` +
        `Language: natural Egyptian Arabic (${language}); English proper nouns may remain in English.\n` +
        `Follow this exact difficulty order:\n${repeatedSlots}\n\n` +
        "For each item: question is 1-2 sentences; answer is 1-8 words; fact is a short useful explanation; " +
        "acceptedAnswers contains only equivalent valid answers; answerRule explains the required specificity. " +
        "Easy must be broadly known, medium requires solid knowledge, and hard should challenge a fan without being obscure or arguable.";
}
function validateGeneratedQuestion(question) {
    if (!question || typeof question !== "object") {
        throw new https_1.HttpsError("internal", "Invalid generated question.");
    }
    for (const key of ["question", "answer", "fact", "answerRule"]) {
        if (typeof question[key] !== "string" || !question[key].trim()) {
            throw new https_1.HttpsError("internal", `Generated field ${key} is invalid.`);
        }
    }
    if (!Array.isArray(question.acceptedAnswers) || question.acceptedAnswers.some((value) => typeof value !== "string")) {
        throw new https_1.HttpsError("internal", "Generated acceptedAnswers is invalid.");
    }
}
function buildChallengeUrl(id) {
    const configured = publicBaseUrl.value().trim().replace(/\/$/, "");
    if (configured)
        return `${configured}/challenge?id=${encodeURIComponent(id)}`;
    const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
    if (!projectId)
        throw new https_1.HttpsError("internal", "Firebase project ID is unavailable.");
    return `https://${region}-${projectId}.cloudfunctions.net/challenge?id=${encodeURIComponent(id)}`;
}
function renderChallenge(data) {
    const type = String(data.type ?? "text");
    const content = escapeHtml(String(data.content ?? ""));
    const imageUrl = safeHttpsUrl(data.imageUrl);
    const audioUrl = safeHttpsUrl(data.audioUrl);
    const media = type === "image" && imageUrl
        ? `<img src="${escapeHtml(imageUrl)}" alt="صورة التحدي">`
        : type === "audio" && audioUrl
            ? `<audio controls autoplay src="${escapeHtml(audioUrl)}"></audio>`
            : "";
    return `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>تحدي معلومات عامة</title><style>${pageStyles()}</style></head><body><main><div class="badge">تحدي معلومات عامة</div>${media}<h1>${content}</h1><p>ابدأ التحدي مع فريقك الآن.</p></main></body></html>`;
}
function renderError(message) {
    return `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>التحدي</title><style>${pageStyles()}</style></head><body><main><h1>${escapeHtml(message)}</h1></main></body></html>`;
}
function pageStyles() {
    return "body{margin:0;min-height:100vh;display:grid;place-items:center;background:#07111f;color:#fff;font-family:Arial,sans-serif;padding:20px;box-sizing:border-box}main{width:min(720px,100%);background:#101d2d;border:1px solid #29435d;border-radius:24px;padding:28px;text-align:center;box-shadow:0 20px 70px #0008}h1{font-size:clamp(28px,7vw,52px);line-height:1.45;margin:24px 0}p{color:#a9bbcd;font-size:18px}.badge{display:inline-block;background:#16d9e3;color:#05131c;padding:8px 14px;border-radius:999px;font-weight:800}img{max-width:100%;max-height:55vh;border-radius:18px;margin-top:22px}audio{width:100%;margin-top:24px}";
}
function asRecord(value) {
    return isPlainObject(value) ? value : {};
}
function isPlainObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}
function requiredString(value, name, maxLength) {
    const text = optionalString(value, maxLength);
    if (!text)
        throw new https_1.HttpsError("invalid-argument", `${name} is required.`);
    return text;
}
function optionalString(value, maxLength) {
    if (value === null || value === undefined)
        return null;
    if (typeof value !== "string")
        throw new https_1.HttpsError("invalid-argument", "Expected a string.");
    const text = value.trim();
    if (!text)
        return null;
    if (text.length > maxLength)
        throw new https_1.HttpsError("invalid-argument", "String is too long.");
    return text;
}
function clampInteger(value, min, max, fallback) {
    const parsed = typeof value === "number" ? Math.trunc(value) : Number.parseInt(String(value ?? ""), 10);
    if (!Number.isFinite(parsed))
        return fallback;
    return Math.max(min, Math.min(max, parsed));
}
function safeHttpsUrl(value) {
    if (typeof value !== "string" || !value.trim())
        return null;
    try {
        const url = new URL(value);
        return url.protocol === "https:" ? url.toString() : null;
    }
    catch {
        return null;
    }
}
function escapeHtml(value) {
    return value.replace(/[&<>'"]/g, (character) => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "'": "&#39;",
        '"': "&quot;",
    })[character] ?? character);
}
//# sourceMappingURL=index.js.map