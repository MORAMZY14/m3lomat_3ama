import '../models/game_models.dart';

abstract final class DemoData {
  static const _categories = <Category>[
    Category(id: 'demo-football', name: 'كرة القدم', image: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800'),
    Category(id: 'demo-geography', name: 'جغرافيا', image: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800'),
    Category(id: 'demo-science', name: 'علوم', image: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800'),
    Category(id: 'demo-movies', name: 'أفلام', image: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800'),
    Category(id: 'demo-history', name: 'تاريخ', image: 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=800'),
    Category(id: 'demo-games', name: 'ألعاب', image: 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800'),
    Category(id: 'demo-anime', name: 'أنمي', image: 'https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?w=800'),
    Category(id: 'demo-tech', name: 'تكنولوجيا', image: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800'),
  ];

  static BootstrapData build() {
    final groups = [
      const CategoryGroup(
        id: 'demo-main',
        name: 'الفئات التجريبية',
        categories: _categories,
      ),
    ];

    final bank = <String, List<(String, String)>>{
      'demo-football': [
        ('كم لاعبًا يبدأ المباراة داخل الملعب لكل فريق؟', '11 لاعبًا'),
        ('من فاز بكأس العالم 2022؟', 'الأرجنتين'),
        ('ما اسم البطولة الأوروبية الأهم للأندية؟', 'دوري أبطال أوروبا'),
      ],
      'demo-geography': [
        ('ما عاصمة مصر؟', 'القاهرة'),
        ('ما أكبر محيط في العالم؟', 'المحيط الهادئ'),
        ('في أي قارة تقع البرازيل؟', 'أمريكا الجنوبية'),
      ],
      'demo-science': [
        ('ما الكوكب المعروف بالكوكب الأحمر؟', 'المريخ'),
        ('ما الرمز الكيميائي للذهب؟', 'Au'),
        ('ما أسرع شيء معروف في الكون؟', 'الضوء'),
      ],
      'demo-movies': [
        ('من أخرج فيلم Titanic؟', 'جيمس كاميرون'),
        ('ما اسم عالم السحرة بطل سلسلة الأفلام الشهيرة؟', 'هاري بوتر'),
        ('أي فيلم فاز بأوسكار أفضل فيلم عام 2020؟', 'Parasite'),
      ],
      'demo-history': [
        ('في أي بلد بُنيت الأهرامات؟', 'مصر'),
        ('من أسس الدولة الأموية؟', 'معاوية بن أبي سفيان'),
        ('في أي عام انتهت الحرب العالمية الثانية؟', '1945'),
      ],
      'demo-games': [
        ('ما الشركة المطورة للعبة Minecraft أصلًا؟', 'Mojang'),
        ('كم لاعبًا في فريق League of Legends؟', '5 لاعبين'),
        ('ما اسم بطل سلسلة God of War؟', 'Kratos'),
      ],
      'demo-anime': [
        ('ما اسم بطل One Piece؟', 'مونكي دي لوفي'),
        ('ما اسم القرية التي ينتمي إليها ناروتو؟', 'قرية الورق'),
        ('من هو بطل Attack on Titan؟', 'إيرين ييغر'),
      ],
      'demo-tech': [
        ('ماذا تعني CPU؟', 'وحدة المعالجة المركزية'),
        ('من طوّر نظام Android في بدايته؟', 'Android Inc.'),
        ('ما البروتوكول المستخدم عادة لتصفح المواقع الآمنة؟', 'HTTPS'),
      ],
    };

    final questions = <GameQuestion>[];
    for (final category in _categories) {
      final rows = bank[category.id]!;
      for (var index = 0; index < rows.length; index++) {
        for (var team = 0; team < 2; team++) {
          questions.add(GameQuestion(
            id: '${category.id}-${index + 1}-t$team',
            categoryId: category.id,
            categoryName: category.name,
            points: const [200, 400, 600][index],
            teamIndex: team,
            difficulty: const ['easy', 'medium', 'hard'][index],
            question: rows[index].$1,
            answer: rows[index].$2,
            fact: index == 2 ? 'هذه بيانات تجريبية محلية، وسيتم استبدالها بقاعدة بياناتك عند اتصال الـ API.' : null,
          ));
        }
      }
    }

    return BootstrapData(groups: groups, questions: questions, audioQuestions: const []);
  }
}
