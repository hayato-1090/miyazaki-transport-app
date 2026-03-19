/// 称号モデル
class AppTitle {
  final String id;
  final String emoji;
  final String name;
  final String condition;
  bool isUnlocked;

  AppTitle({
    required this.id,
    required this.emoji,
    required this.name,
    required this.condition,
    this.isUnlocked = false,
  });
}

/// 称号一覧
List<AppTitle> allTitles() => [
      AppTitle(
        id: 'beginner',
        emoji: '🌱',
        name: '宮崎ビギナー',
        condition: 'アプリ初回起動',
        isUnlocked: true, // 初回から解放
      ),
      AppTitle(
        id: 'bus_master',
        emoji: '🚌',
        name: 'バス通',
        condition: 'バス検索10回',
      ),
      AppTitle(
        id: 'walker',
        emoji: '🚶',
        name: 'ウォーカー',
        condition: '合計歩行距離5km',
      ),
      AppTitle(
        id: 'runner',
        emoji: '🏃',
        name: 'ランナー',
        condition: '合計歩行距離20km',
      ),
      AppTitle(
        id: 'collector',
        emoji: '🪙',
        name: 'コレクター',
        condition: 'コイン100枚取得',
      ),
      AppTitle(
        id: 'miyazaki_master',
        emoji: '🏆',
        name: '宮崎マスター',
        condition: '全クエスト達成',
      ),
    ];
