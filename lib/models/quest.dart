/// クエストモデル
class Quest {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  int currentCount;
  final int rewardCoins;
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardCoins,
    this.isCompleted = false,
  });

  double get progress =>
      isCompleted ? 1.0 : (currentCount / targetCount).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentCount': currentCount,
        'isCompleted': isCompleted,
      };

  Quest copyWithProgress({int? currentCount, bool? isCompleted}) => Quest(
        id: id,
        title: title,
        description: description,
        targetCount: targetCount,
        currentCount: currentCount ?? this.currentCount,
        rewardCoins: rewardCoins,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
