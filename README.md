# miyazaki-transport-app
宮崎の交通手段の情報が一瞬で分かるようなアプリ

## 機能
- 🚌 交通手段の情報表示（バス・電車・タクシー・自転車）
- 🗺️ 現在地マップ表示（Google Maps）
- 📍 逆ジオコーディング（現在地の住所表示）
- 🛣️ ルート検索（Google Directions API）
- 💰 料金計算機

## セットアップ

### 前提条件
- Flutter SDK がインストール済みであること
- Google Cloud Console で以下の API が有効化されていること:
  - Maps SDK for Android
  - Maps SDK for iOS
  - Geocoding API
  - Directions API

### 1. `.env` ファイルの作成
プロジェクトルートに `.env` ファイルを作成し、Google Maps API キーを設定してください：
```
GOOGLE_MAPS_API_KEY=あなたのAPIキー
```
> ⚠️ `.env` ファイルは `.gitignore` で除外済みです。リポジトリにコミットしないでください。

### 2. Android の設定
`android/local.properties` に API キーを追加してください：
```
GOOGLE_MAPS_API_KEY=あなたのAPIキー
```
この値は `android/app/build.gradle` の `manifestPlaceholders` 経由で `AndroidManifest.xml` に注入されます。

### 3. iOS の設定
`ios/Flutter/Debug.xcconfig` および `ios/Flutter/Release.xcconfig` に以下を追加してください：
```
GOOGLE_MAPS_API_KEY=あなたのAPIキー
```
この値は `ios/Runner/Info.plist` の `$(GOOGLE_MAPS_API_KEY)` に展開され、`AppDelegate.swift` で `GMSServices.provideAPIKey()` に渡されます。

または Xcode で `ios/Runner/Runner.xcodeproj` を開き、
Build Settings > User-Defined に `GOOGLE_MAPS_API_KEY` を追加することもできます。

### 4. 依存関係のインストール
```bash
flutter pub get
```

iOS の場合は CocoaPods もインストールしてください：
```bash
cd ios && pod install && cd ..
```

### 5. 実行
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

## セキュリティ
- API キーは `.env` ファイルで管理（リポジトリにコミットしない）
- `.gitignore` に `.env*` を追加済み
- Google Cloud Console で API キーの制限（Android/iOS アプリ制限）を設定することを推奨

