import 'package:flutter/material.dart';
import '../services/coin_service.dart';

/// ショップ画面
class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CoinService _coinService = CoinService();
  List<String> _ownedSkins = ['red'];
  final _adMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOwnedSkins();
    _adMessageController.text = _coinService.customAdMessage;
  }

  @override
  void dispose() {
    _adMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnedSkins() async {
    final owned = await _coinService.getOwnedSkins();
    setState(() => _ownedSkins = owned);
  }

  Future<void> _purchaseOrSelectSkin(
      String skinId, int price, String name) async {
    if (_ownedSkins.contains(skinId)) {
      final ok = await _coinService.selectSkin(skinId);
      if (ok && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name を装備しました！')),
        );
      }
    } else {
      if (_coinService.totalCoins < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('コインが足りません（必要: $price🪙）')),
        );
        return;
      }
      final ok = await _coinService.purchaseSkin(skinId, price);
      if (ok && mounted) {
        await _loadOwnedSkins();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name を購入しました！')),
        );
      }
    }
  }

  Future<void> _handleAdPurchase() async {
    final message = _adMessageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージを入力してください')),
      );
      return;
    }
    final ok = await _coinService.purchaseAd(message);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '広告枠を更新しました！' : 'コインが足りません（必要: 500🪙）'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛍️ ショップ'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // コイン残高
          Card(
            color: Colors.amber.shade50,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    '所持コイン: ${_coinService.totalCoins}枚',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- マーカースキンセクション ---
          _SectionHeader(title: '🎨 マーカースキン'),
          const SizedBox(height: 8),
          ..._buildSkinItems(),
          const SizedBox(height: 20),

          // --- 広告枠セクション ---
          _SectionHeader(title: '📢 広告枠（カスタムメッセージ）'),
          const SizedBox(height: 8),
          _buildAdSection(),
        ],
      ),
    );
  }

  List<Widget> _buildSkinItems() {
    final skins = [
      _SkinItem(id: 'red', name: '赤（デフォルト）', price: 0, emoji: '🔴'),
      _SkinItem(id: 'blue', name: '青', price: 50, emoji: '🔵'),
      _SkinItem(id: 'white', name: '白', price: 50, emoji: '⚪'),
    ];

    return skins.map((skin) {
      final isOwned = _ownedSkins.contains(skin.id);
      final isSelected = _coinService.selectedSkin == skin.id;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Text(skin.emoji, style: const TextStyle(fontSize: 28)),
          title: Text(skin.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(skin.price == 0 ? '無料' : '${skin.price}🪙'),
          trailing: isSelected
              ? const Chip(
                  label: Text('使用中'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                )
              : ElevatedButton(
                  onPressed: () =>
                      _purchaseOrSelectSkin(skin.id, skin.price, skin.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned ? Colors.blue : Colors.orange,
                  ),
                  child: Text(isOwned ? '使用する' : '購入'),
                ),
        ),
      );
    }).toList();
  }

  Widget _buildAdSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _coinService.adUnlocked
                        ? 'ホーム画面にメッセージを表示'
                        : '500🪙でホーム画面に好きなメッセージを表示',
                    style: TextStyle(
                        color: _coinService.adUnlocked
                            ? Colors.black87
                            : Colors.grey[600]),
                  ),
                ),
                if (!_coinService.adUnlocked)
                  Chip(
                    label: const Text('500🪙'),
                    backgroundColor: Colors.orange.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adMessageController,
              enabled: _coinService.adUnlocked ||
                  _coinService.totalCoins >= 500,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleAdPurchase,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _SkinItem {
  final String id;
  final String name;
  final int price;
  final String emoji;
  _SkinItem(
      {required this.id,
      required this.name,
      required this.price,
      required this.emoji});
}
