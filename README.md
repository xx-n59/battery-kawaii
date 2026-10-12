# battery-kawaii

**日本語** | [English](README.en.md)

Macのバッテリー残量を、表情の変わるキャラクターと一緒にメニューバーへ表示するアプリです。SwiftUIとIOKitで作られています。

## 主な機能

- **残量と充電状態を表示**：メニューバーでバッテリーの状態を確認できます。
- **残量に応じた表情**：充電中はハートの目、満充電では星の目、残量が少なくなると疲れた表情になります。
- **6種類のデザイン**：クラシック・ねこ・うさぎ・くま・ロボット・ピクセルから選べます。選択は保存され、次回起動時も引き継がれます。
- **バッテリーの詳細**：残り時間または充電完了までの時間、健康状態、サイクルカウントを表示します。
- **ダークモード対応**：macOSの外観設定に合わせて配色が切り替わります。
- **日本語・英語対応**：macOSの設定言語に合わせて表示が切り替わります。

## 動作・開発環境

- macOS 15.4以降
- 内蔵バッテリーを搭載したMac（MacBook Air、MacBook Proなど）
- ビルドには、macOS 15.4以降のSDKを含むXcodeが必要です。

外部ライブラリのインストールは不要です。バッテリー情報はMac本体から取得します。残り時間や健康状態などは、機種やOSから取得できる情報によって表示が異なります。

## ビルドと起動

1. リポジトリを取得し、Xcodeでプロジェクトを開きます。

   ```sh
   git clone https://github.com/xx-n59/battery-kawaii.git
   cd battery-kawaii
   open battery-kawaii.xcodeproj
   ```

2. スキームに`battery-kawaii`、実行先に`My Mac`を選択します。
3. 署名設定を求められた場合は、アプリターゲットの「Signing & Capabilities」で開発チームを選択します。
4. `⌘R`でビルドして起動します。

起動するとメニューバーにキャラクターと残量が表示されます。通常のアプリウィンドウやDockアイコンは表示されません。

## 使い方

1. メニューバーのキャラクターまたは残量をクリックして、詳細画面を開きます。
2. 「デザイン」で好きなキャラクターを選ぶと、メニューバーにもすぐ反映されます。
3. アプリを閉じるには、詳細画面の「終了」をクリックします。

## 言語対応

アプリとREADMEは日本語・英語に対応しています。アプリはmacOSの優先言語の順序に従い、対応している言語を自動で選びます。日本語・英語のどちらも優先言語に含まれていない場合は英語で表示します。

macOSの「言語と地域」でアプリ専用の言語を指定している場合は、その設定が優先されます。言語設定を変更したあとは、アプリを終了して再起動してください。デザインの選択はそのまま引き継がれます。

## 開発

主なファイルは次のとおりです。

| ファイル | 役割 |
| --- | --- |
| [battery_kawaiiApp.swift](battery-kawaii/battery_kawaiiApp.swift) | アプリの起動、メニューバー表示、デザイン設定の保存 |
| [BatteryMonitor.swift](battery-kawaii/BatteryMonitor.swift) | バッテリー情報の取得と監視 |
| [BatteryCharacterView.swift](battery-kawaii/BatteryCharacterView.swift) | キャラクター・表情の描画、メニューバー画像のキャッシュ |
| [BatteryDesign.swift](battery-kawaii/BatteryDesign.swift) | デザインの定義と選択画面 |
| [BatteryDetailView.swift](battery-kawaii/BatteryDetailView.swift) | バッテリーの詳細画面 |
| [Localizable.xcstrings](battery-kawaii/Localizable.xcstrings) | 日本語・英語の翻訳と複数形の定義 |
| [battery_kawaiiTests.swift](battery-kawaiiTests/battery_kawaiiTests.swift) | 監視処理と画像キャッシュの単体テスト |
| [LocalizationTests.swift](battery-kawaiiTests/LocalizationTests.swift) | 言語選択、翻訳、時間と回数の表示のテスト |

バックグラウンド処理を抑えるため、通常は電源情報の変更通知を受けて更新します。通知の登録に失敗した場合だけ60秒間隔の監視に切り替えます。健康状態とサイクルカウントは詳細画面を開いたときに取得し、5分間キャッシュします。

### テスト

リポジトリのルートで実行します。Xcodeを別の場所にインストールしている場合は、`DEVELOPER_DIR`を変更してください。

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project battery-kawaii.xcodeproj \
  -scheme battery-kawaii \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/battery-kawaii-build \
  -only-testing:battery-kawaiiTests \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```

このコマンドは、監視の開始・停止、変更時のみの更新、詳細情報のキャッシュ、残り時間、外観やデザイン変更時の画像キャッシュを検証します。実機のバッテリー計測や画面操作の確認は別途行ってください。

言語ごとの検証には、上のコマンドへ`-testLanguage ja -testRegion JP`または`-testLanguage en -testRegion US`を追加します。翻訳は`Localizable.xcstrings`で管理しています。言語を追加するときは、翻訳とプロジェクトの対応言語を追加してください。
