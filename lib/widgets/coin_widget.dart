import 'package:flutter/material.dart';
import '../services/coin_service.dart';

/// コイン枚数表示ウィジェット（AppBarなどに埋め込む）
class CoinWidget extends StatelessWidget {
  const CoinWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coins = CoinService().totalCoins;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
