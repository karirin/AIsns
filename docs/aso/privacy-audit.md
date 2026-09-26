# AImate プライバシー実装監査

更新日: 2026-09-25

## 結論

現在公開中のApp Storeページは「データの収集なし」と表示される一方、アプリはユーザーが入力したプロフィール、キャラクター設定、投稿、コメント、チャット、問い合わせ、画像をFirebaseへ保存し、AI生成用プロンプトをFirebase Functions経由でOpenAI APIへ送信する。Google Mobile Adsも組み込まれている。このため、少なくとも「データの収集なし」を維持できるかはApp Store Connectの定義に照らして所有者が再確認する必要がある。

これはコード調査による不整合候補であり、Apple上の最終分類や違反を断定するものではない。SDK事業者側の設定、保持期間、データの関連付け、トラッキング利用はコードだけでは確定できない。

## データフロー

| データ | 送信先・保存先 | 目的 | 保存について確認できたこと | 主な根拠 |
|---|---|---|---|---|
| 端末内で生成したユーザーID（UUID） | Firebase Realtime Database、Firebase Storageのパス | アカウント相当のデータ分離、投稿・チャット・フォロー等の紐付け | UserDefaultsに保存。退会時に削除し、新しいIDへ切り替わる | `Config/FirebaseConfig.swift`、`Services/FirebaseDatabaseManager.swift` |
| プロフィール名、自己紹介、アバター | Firebase Realtime Database / Storage | プロフィール表示 | 退会処理に削除コードあり。バックアップやサーバー側保持期間は未確認 | `saveUserProfile`、`uploadUserAvatar`、`deleteCurrentUserData` |
| AIキャラクター名、外見、背景、性格、口調、呼び方、関係性、メモ等 | Firebase Realtime Database / Storage | キャラクター作成、表示、AI応答 | キャラクター削除・退会時の削除コードあり。公開設定があり、共有対象になる場合がある | `Models/OshiCharacter.swift`、`saveOshi`、`uploadOshiAvatar` |
| 投稿本文、画像、コメント、リアクション、フォロー、ブックマーク、リポスト | Firebase Realtime Database / Storage | タイムライン、SNS機能、AI反応 | 投稿・キャラクター・退会時の削除コードあり。一部は公開タイムラインや他ユーザー向け通知に保存される | `savePost`、`addComment`、`addReaction`、`uploadPostImage` |
| 1対1チャット本文 | Firebase Realtime Database | 会話履歴表示、AI返信生成 | チャット削除・退会時の削除コードあり。サーバー側保持期間は未確認 | `addMessage`、`deleteChatRoom` |
| AI生成用プロンプト | Firebase Functions（asia-northeast1）からOpenAI API | コメント、返信、チャット、AI投稿の生成 | FunctionsはOpenAIへ `store: false` を指定。Firebase Functionsのログ・OpenAI側の不正利用監視等の保持は契約・管理画面未確認 | `Services/OpenAIService.swift`、`functions/index.js` |
| 問い合わせ本文 | Firebase Realtime Database `contacts/{userId}` | サポート対応 | 退会時に削除コードあり。個別問い合わせの通常時保持期間は未確認 | `Views/HelpModalView.swift`、`updateContact` |
| 広告リクエストに伴う端末・広告操作等 | Google Mobile Ads | バナー、ネイティブ、インタースティシャル、リワード広告の配信・測定 | SDK側の収集項目、パーソナライズ設定、保持期間はコードだけでは未確認 | `AICaringSNSApp.swift`、`Ad/`、`ViewModels/AdViewModel.swift`、`Info.plist` |
| アプリの正当性を示す情報 | Firebase App Check（実機はApp Attest、シミュレータはDebug provider） | 不正利用防止、Functions保護 | App Checkトークンの保持やログはFirebase設定未確認 | `AICaringSNSApp.swift`、`functions/index.js` |
| 利用状況・診断候補 | Firebase Analyticsパッケージはリンク済み | 分析候補 | `GoogleService-Info.plist` ではAnalytics無効、アプリコードに明示的なイベント送信なし。ただしリリース設定・SDKの最終挙動はビルドとFirebase管理画面で再確認が必要 | `AIsns.xcodeproj/project.pbxproj`、`GoogleService-Info.plist` |
| 購入商品・取引状態 | Apple StoreKit（端末上で照合） | Plus権限付与、購入・復元 | アプリ独自サーバーへの取引保存は確認できない。Apple/App Store Connect側の保持はAppleの運用に従う | `Services/Subscriptions/SubscriptionStore.swift` |
| 評価依頼の利用日数・セッション数・完了操作数・最終依頼試行日・版 | 端末内UserDefaultsのみ | 評価依頼の頻度制御 | 外部送信なし。会話本文や感情は保存しない | `Services/ReviewRequestManager.swift` |

## SDK・サービス

- Firebase Core / Realtime Database / Storage / Functions / App Check
- Firebase Analytics（依存関係には存在するが、設定ファイル上は無効、明示イベントなし）
- Google Mobile Ads
- OpenAI API（Firebase Functions経由）
- Apple StoreKit
- Apple PhotosUI（ユーザーが選択した画像のみアプリが受け取り、選択後にFirebase Storageへ送信可能）

Firebase Authenticationの実利用は確認できず、端末生成UUIDを識別子として使っている。通知のAPNs登録・位置情報・連絡先・マイク・カメラの直接取得コードは今回の範囲では確認していない。

## App Store Connectで確認すべき項目

最終的な回答は、Appleの質問文と各SDKの最新Data Safety資料に照らして決める。コードだけで分類を確定しない。

- 「データの収集なし」を維持できるか。Firebaseに保存されるユーザーコンテンツと識別子は特に再確認する。
- User Content: Photos or Videos、Other User Content、Customer Support、Emails or Text Messages相当の該当範囲。
- Identifiers: User ID、Device ID相当。端末UUIDとGoogle Mobile Ads/App Checkが該当するか。
- Usage Data / Advertising Data / Diagnostics: Google Mobile AdsおよびFirebase SDKの実設定に基づく該当有無。
- Purchases: StoreKit取引状態を開発者が「収集」する扱いになるか。
- 各データがユーザーにリンクされるか。端末UUID、投稿の公開設定、共有キャラクターとの関係を含める。
- Google Mobile Adsが他社データとのトラッキングに使われる構成か。コードにATT要求やUMP同意画面は見当たらないため、広告設定と対象地域を確認する。
- プライバシーマニフェストとRequired Reason APIの最終アーカイブ検査結果。

## コードだけでは確認できない事項

- Firebase Realtime Database / StorageのSecurity Rules、バックアップ、TTL、ログ、管理者アクセス、削除後の復旧可能期間。
- Firebase Functionsの本番ログ保持、Secret Manager、デプロイ済みコードがリポジトリと一致するか。
- OpenAI API契約・データ保持設定と、`store: false` 以外の保持条件。
- Google Mobile Adsのパーソナライズ、地域別同意、テスト端末、本番配信、広告・診断データの詳細。
- App Store Connectで現在選択されているプライバシー回答。
- 公開プライバシーポリシーの法的妥当性、運営者情報、正式な問い合わせ先、保存期間。
- 実際のFirebase Rules上で公開投稿・非公開投稿が誰から読めるか。

## 公開ポリシーへの変更草案（未反映）

現行の `public/privacy.html` は、ユーザーコンテンツ、Firebase、OpenAI API、Google Mobile Ads、StoreKit、削除機能を概ね記載している。断定的な改定はせず、公開前に次の追記・具体化を法務・運営確認する。

1. 「端末単位の識別子」が認証アカウントではなく端末で生成したUUIDであることと、端末変更・アプリ削除時の扱い。
2. AI生成時に投稿・コメント・チャット・キャラクター設定の必要部分がFirebase FunctionsとOpenAI APIへ送信されること。
3. 公開設定されたキャラクター・投稿が他ユーザーに表示され得ること。
4. Firebase、OpenAI、Google Mobile Adsごとの保持期間、または保持期間を決める基準。
5. App Storeページへの循環参照ではない、実在する問い合わせ手段。現状確認できたのはアプリ内問い合わせフォームのみ。

公開中の法的文書とApp Storeの申告は、この監査を基に所有者が管理画面・契約・運用を確認した後で更新する。
