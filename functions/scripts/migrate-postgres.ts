import { applicationDefault, initializeApp } from "firebase-admin/app";
import { Firestore, getFirestore } from "firebase-admin/firestore";
import pg, { Client } from "pg";

async function main(): Promise<void> {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error("Set DATABASE_URL before running this migration.");
  }

  initializeApp({ credential: applicationDefault() });
  const db = getFirestore();
  const sql = new pg.Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await sql.connect();

  try {
    await migrateTable(sql, db, "category_groups", "categoryGroups", (row) => ({
      name: row.name,
      sortOrder: row.sort_order ?? 0,
    }));

    await migrateTable(sql, db, "categories", "categories", (row) => ({
      name: row.name,
      arabicName: row.arabic_name,
      image: row.category_image,
      groupId: row.group_id,
      createdAt: row.created_at,
    }));

    await migrateTable(sql, db, "questions", "questions", (row) => ({
      categoryId: row.category_id,
      categoryName: row.category_name,
      points: row.points,
      teamIndex: row.team_index,
      difficulty: row.difficulty,
      question: row.question,
      answer: row.answer,
      imageUrl: row.image_url,
      questionImageUrl: row.question_image_url,
      fact: row.fact,
      acceptedAnswers: row.accepted_answers ?? [],
      answerRule: row.answer_rule,
      used: row.used_at != null,
      usedAt: row.used_at,
      createdAt: row.created_at,
    }));

    await migrateTable(sql, db, "audio_questions", "audioQuestions", (row) => ({
      categoryId: row.category_id,
      categoryName: row.category_name,
      points: row.points,
      teamIndex: row.team_index,
      difficulty: row.difficulty,
      questionText: row.question_text,
      audioUrl: row.audio_url,
      answer: row.answer,
      transcript: row.transcript,
      revealImageUrl: row.reveal_image_url,
      used: row.used_at != null,
      usedAt: row.used_at,
      createdAt: row.created_at,
    }));

    await migrateTable(sql, db, "challenges", "challenges", (row) => ({
      type: row.type,
      content: row.content,
      imageUrl: row.image_url,
      audioUrl: row.audio_url,
      metadata: row.metadata,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    }));

    console.log("PostgreSQL to Firestore migration completed.");
  } finally {
    await sql.end();
  }
}

async function migrateTable(
  sql: Client,
  db: Firestore,
  sqlTable: string,
  firestoreCollection: string,
  transform: (row: Record<string, any>) => Record<string, unknown>,
): Promise<void> {
  let rows: Record<string, any>[];
  try {
    const result = await sql.query(`SELECT * FROM ${sqlTable}`);
    rows = result.rows;
  } catch (error) {
    console.warn(`Skipping ${sqlTable}:`, error instanceof Error ? error.message : error);
    return;
  }

  for (let offset = 0; offset < rows.length; offset += 400) {
    const batch = db.batch();
    for (const row of rows.slice(offset, offset + 400)) {
      const ref = db.collection(firestoreCollection).doc(String(row.id));
      batch.set(ref, removeUndefined(transform(row)), { merge: true });
    }
    await batch.commit();
  }
  console.log(`${sqlTable}: migrated ${rows.length} rows.`);
}

function removeUndefined(value: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(value).filter(([, item]) => item !== undefined));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
