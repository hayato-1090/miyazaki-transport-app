import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/coin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env ファイルを読み込む
  await dotenv.load(fileName: ".env");
  // コインサービスを初期化（SharedPreferences）
  await CoinService().initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miyazaki Transport App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: HomeScreen(),
      locale: Locale('ja'),
    );
  }
}
