"use strict";

const { applicationDefault, initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");

async function main() {
  initializeApp({ credential: applicationDefault() });
  const db = getFirestore();

  const categories = [
    ["demo-football", "كرة القدم", "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800"],
    ["demo-geography", "جغرافيا", "https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800"],
    ["demo-science", "علوم", "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800"],
    ["demo-movies", "أفلام", "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800"],
    ["demo-history", "تاريخ", "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=800"],
    ["demo-games", "ألعاب", "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800"],
    ["demo-anime", "أنمي", "https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?w=800"],
    ["demo-tech", "تكنولوجيا", "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800"],
  ];

  const bank = {
    "demo-football": [["كم لاعبًا يبدأ المباراة داخل الملعب لكل فريق؟", "11 لاعبًا"], ["من فاز بكأس العالم 2022؟", "الأرجنتين"], ["ما اسم البطولة الأوروبية الأهم للأندية؟", "دوري أبطال أوروبا"]],
    "demo-geography": [["ما عاصمة مصر؟", "القاهرة"], ["ما أكبر محيط في العالم؟", "المحيط الهادئ"], ["في أي قارة تقع البرازيل؟", "أمريكا الجنوبية"]],
    "demo-science": [["ما الكوكب المعروف بالكوكب الأحمر؟", "المريخ"], ["ما الرمز الكيميائي للذهب؟", "Au"], ["ما أسرع شيء معروف في الكون؟", "الضوء"]],
    "demo-movies": [["من أخرج فيلم Titanic؟", "جيمس كاميرون"], ["ما اسم عالم السحرة بطل سلسلة الأفلام الشهيرة؟", "هاري بوتر"], ["أي فيلم فاز بأوسكار أفضل فيلم عام 2020؟", "Parasite"]],
    "demo-history": [["في أي بلد بُنيت الأهرامات؟", "مصر"], ["من أسس الدولة الأموية؟", "معاوية بن أبي سفيان"], ["في أي عام انتهت الحرب العالمية الثانية؟", "1945"]],
    "demo-games": [["ما الشركة المطورة للعبة Minecraft أصلًا؟", "Mojang"], ["كم لاعبًا في فريق League of Legends؟", "5 لاعبين"], ["ما اسم بطل سلسلة God of War؟", "Kratos"]],
    "demo-anime": [["ما اسم بطل One Piece؟", "مونكي دي لوفي"], ["ما اسم القرية التي ينتمي إليها ناروتو؟", "قرية الورق"], ["من هو بطل Attack on Titan؟", "إيرين ييغر"]],
    "demo-tech": [["ماذا تعني CPU؟", "وحدة المعالجة المركزية"], ["من طوّر نظام Android في بدايته؟", "Android Inc."], ["ما البروتوكول المستخدم عادة لتصفح المواقع الآمنة؟", "HTTPS"]],
  };

  const batch = db.batch();
  batch.set(db.collection("categoryGroups").doc("demo-main"), {
    name: "الفئات التجريبية",
    sortOrder: 0,
  });

  for (const [id, name, image] of categories) {
    batch.set(db.collection("categories").doc(id), {
      name,
      arabicName: name,
      image,
      groupId: "demo-main",
      createdAt: FieldValue.serverTimestamp(),
    });

    const rows = bank[id];
    rows.forEach(([question, answer], difficultyIndex) => {
      for (let teamIndex = 0; teamIndex < 2; teamIndex += 1) {
        batch.set(db.collection("questions").doc(`${id}-${difficultyIndex + 1}-t${teamIndex}`), {
          categoryId: id,
          categoryName: name,
          points: [200, 400, 600][difficultyIndex],
          teamIndex,
          difficulty: ["easy", "medium", "hard"][difficultyIndex],
          question,
          answer,
          fact: "بيانات تجريبية أولية.",
          acceptedAnswers: [],
          answerRule: "اقبل الإجابة المطابقة في المعنى.",
          used: false,
          usedAt: null,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    });
  }

  await batch.commit();
  console.log("Demo categories and questions seeded successfully.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
