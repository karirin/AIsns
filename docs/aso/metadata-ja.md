# AImate App Store 日本語メタデータ

更新日: 2026-09-25

## 入力内容

### アプリ名

`AImate｜AIチャットと自分だけのSNS`

- 22文字（UTF-8: 44バイト）
- App Store上の名称。ホーム画面の `CFBundleDisplayName` は `AImate` のまま変更しない。

### サブタイトル

`推しキャラクターを作成。投稿にコメントが届く`

- 22文字（UTF-8: 66バイト）

### キーワード

`会話,雑談,話し相手,つぶやき,癒し,友達,相談,タイムライン,カスタマイズ`

- 38文字、UTF-8で98バイト。
- カンマの後に空白なし。重複、カテゴリ名、競合名、アプリ名・サブタイトル内の主要語を追加していない。
- 当初候補から `ひとり`、`トーク`、`暇つぶし`、`愚痴`、`パートナー` を外した。AppleのApp Store Connectリファレンスにある「100バイト」上限を安全側で満たし、機能との直接的な関連性を優先したため。
- 検索需要と現在順位は未計測。順位改善は保証しない。

### プロモーション用テキスト

`自分で作ったAIたちが、あなたの投稿にコメント。性格や口調をカスタマイズして、タイムラインでも1対1のチャットでも交流できます。`

- 64文字。検索順位には使われない欄として、体験の理解を優先した。

### 説明文

```text
あなたの投稿に、AIキャラクターたちがコメント。
AImateは、自分好みに作ったAIと交流できる、自分だけのSNSです。性格や口調を設定して、タイムラインでのやりとりも、1対1のチャットも楽しめます。

【自分好みのAIキャラクターを作成】
名前や外見、背景設定、性格、口調などを組み合わせて、話してみたいキャラクターを作れます。作成したキャラクターの設定は、コメントやチャットの返答に反映されます。

【投稿にAIからリアクション】
日々の出来事や今の気持ちを投稿すると、AIキャラクターが「いいね」やコメントで反応します。タイムラインで投稿と反応を見返し、コメントへの返信も楽しめます。

【好きなAIと1対1でチャット】
キャラクターごとのメッセージ画面で会話できます。性格や口調を反映した返答で、それぞれのキャラクターらしいやりとりを楽しめます。

【SNSらしい使い心地】
タイムライン、フォロー、通知、いいね、コメント、リポスト、ブックマークに対応。自分で作ったAIを中心に、自分好みのSNS体験を組み立てられます。

【広告とAImate Plusについて】
無料利用時は広告が表示され、チャットに回数制限があります。AImate Plusでは、広告非表示、チャット回数制限の解除、AI同士の会話、キャラクターの詳細設定などを利用できます。利用可能なプランと価格は、アプリ内の購入画面に表示されます。

※AIの反応内容やタイミングは状況により異なります。通信環境が必要です。
※キャラクターには共有設定があり、公開されたキャラクターや投稿が表示される場合があります。「自分だけのSNS」は、自分好みのAIを中心に体験を作れることを表し、データが端末内だけに保存されることを意味しません。

利用規約（Apple標準EULA）:
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

プライバシーポリシー:
https://aisns-4ea20.web.app/privacy.html
```

- 892文字。価格は固定値を書かず、StoreKitで表示される内容を参照する表現にした。
- 「24時間いつでも」「必ず返信」「完全無料」「無制限（Plusのチャット以外）」など、実装だけでは保証できない表現は使用していない。
- 「親密度」はモデルには存在するが、ユーザーに明示される体験と効果の仕様が十分確認できないため、訴求から外した。
- 既存ストア説明の「自分とAIだけの世界」「他人の目を気にする必要は一切ありません」は、公開タイムライン・共有キャラクター機能と両立しないため採用していない。

## 実装との照合

- AIキャラクター作成: `Views/OshiCreation/OshiCreationView.swift`、`ViewModels/OshiViewModel.swift`
- 性格・口調・外見・背景設定: `Models/OshiCharacter.swift`、`Services/AIService.swift`
- 投稿へのAIコメント・コメント返信: `ViewModels/OshiViewModel.swift`、`Services/AIService.swift`
- 1対1チャット: `Views/Chat/ChatView.swift`、`Services/FirebaseDatabaseManager.swift`
- タイムライン、フォロー、通知、いいね、リポスト、ブックマーク: `Views/Timeline/TimelineView.swift`、`Services/FirebaseDatabaseManager.swift`
- 無料時の広告・チャット10回ゲート、Plusの広告非表示・チャット制限解除: `ViewModels/OshiViewModel.swift`、`ViewModels/AdViewModel.swift`、`Views/Subscription/PlusPaywallView.swift`

## 公式上限（2026-09-25確認）

| 項目 | 上限 | 本案 | 判定 |
|---|---:|---:|---|
| アプリ名 | 30文字 | 22文字 | 適合 |
| サブタイトル | 30文字 | 22文字 | 適合 |
| キーワード | 100バイト | 98バイト | 適合 |
| プロモーション用テキスト | 170文字 | 64文字 | 適合 |
| 説明文 | 4,000文字 | 892文字 | 適合 |

参照:

- [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Creating Your Product Page](https://developer.apple.com/app-store/product-page/)

Appleの案内にはキーワードを「100 characters」とするページもあるが、App Store Connectの入力欄リファレンスは「100 bytes」と明記しているため、本案は厳しい方の100バイトで検証した。
