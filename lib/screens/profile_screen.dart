import 'package:flutter/material.dart';
import '../services/coin_service.dart';
import '../data/titles_data.dart';

/// プロフィール画面
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CoinService _coinService = CoinService();

  @override
  Widget build(BuildContext context) {
    final quests = _coinService.quests;
    final completedQuests = quests.where((q) => q.isCompleted).length;
    final allDone = completedQuests == quests.length && quests.isNotEmpty;
    final titles = _buildTitles(allDone);

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 プロフィール'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- コイン表示 ---
          Card(
            color: Colors.amber.shade50,
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    '${_coinService.totalCoins}枚',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const Text('所持コイン', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 統計 ---
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 統計',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _statRow('🗺️ 総ルート設定回数',
                      '${_coinService.routeCount}回'),
                  _statRow('🚌 バス検索回数',
                      '${_coinService.busSearchCount}回'),
                  _statRow('🎯 達成クエスト数',
                      '$completedQuests / ${quests.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 称号・バッジ ---
          const Text('🏅 称号・バッジ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...titles.map((t) => _TitleCard(title: t)).toList(),
        ],
      ),
    );
  }

  List<AppTitle> _buildTitles(bool allQuestsDone) {
    final quests = _coinService.quests;
    final completedQuestsCount = quests.where((q) => q.isCompleted).length;
    final busSearchCount = _coinService.busSearchCount;

    final titles = allTitles();
    for (final t in titles) {
      switch (t.id) {
        case 'beginner':
          t.isUnlocked = true;
          break;
        case 'bus_master':
          t.isUnlocked = busSearchCount >= 10;
          break;
        case 'collector':
          t.isUnlocked = _coinService.totalCoins >= 100;
          break;
        case 'miyazaki_master':
          t.isUnlocked = allQuestsDone && completedQuestsCount > 0;
          break;
      }
    }
    return titles;
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(fontSize: 14))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  final AppTitle title;
  const _TitleCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: title.isUnlocked ? Colors.white : Colors.grey.shade100,
      child: ListTile(
        leading: Text(
          title.emoji,
          style: TextStyle(
            fontSize: 28,
            color: title.isUnlocked ? null : Colors.grey,
          ),
        ),
        title: Text(
          title.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: title.isUnlocked ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          title.condition,
          style: TextStyle(
            color: title.isUnlocked ? Colors.grey[600] : Colors.grey,
          ),
        ),
        trailing: title.isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock_outline, color: Colors.grey),
      ),
    );
  }
}
