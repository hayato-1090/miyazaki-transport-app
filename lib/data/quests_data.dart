import '../models/quest.dart';

/// 初期クエスト一覧
List<Quest> initialQuests() => [
      Quest(
        id: 'first_step',
        title: 'はじめの一歩',
        description: 'ルートを1回設定しよう',
        targetCount: 1,
        rewardCoins: 10,
      ),
      Quest(
        id: 'walker',
        title: 'ウォーカー',
        description: 'ルートを設定して3回歩こう',
        targetCount: 3,
        rewardCoins: 30,
      ),
      Quest(
        id: 'explorer',
        title: '探検家',
        description: 'ルートを設定して10回歩こう',
        targetCount: 10,
        rewardCoins: 100,
      ),
      Quest(
        id: 'coin_hunter',
        title: 'コインハンター',
        description: 'コインを50枚集めよう',
        targetCount: 50,
        rewardCoins: 20,
      ),
      Quest(
        id: 'bus_lover',
        title: 'バス愛好家',
        description: 'バス検索を5回使おう',
        targetCount: 5,
        rewardCoins: 25,
      ),
    ];
