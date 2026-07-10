# github-account-recovered-counter

![recovered accounts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/hydh/github-account-recovered-counter/main/counter.json)
![GitHub 3rd-party login](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/hydh/github-account-recovered-counter/main/badge.json)

GitHub のプライマリメールアドレスが未認証だと、サードパーティサービスへの
GitHub OAuth ログインが `unverified_user_email` エラーで拒否されます。
このリポジトリは:

1. その状態を自分のトークンで定期観測し、**「制限中 → 解除済み」の遷移を
   git 履歴に証跡として残すバッジ**を提供します
2. 同じ仕組みで回復した全ユーザーを **通し番号付きでカウントする名簿**
   （[registry.json](registry.json)）を管理します

## 自分のバッジを作る

1. このリポジトリを **フォーク**する（public のまま。バッジを外部参照するため）。
2. classic PAT を `user:email` スコープ**のみ**で発行する
   （Settings → Developer settings → Personal access tokens）。
3. フォークの Settings → Secrets and variables → Actions に
   `EMAIL_CHECK_PAT` として登録する。
4. Actions タブでワークフローを有効化し、`Check primary email verification`
   を手動実行（workflow_dispatch）。以降は毎日1回自動実行される。
5. README 等にバッジを貼る（`USER` を自分のログイン名に置き換え）:

```markdown
![GitHub 3rd-party login](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/USER/github-account-recovered-counter/main/badge.json)
```

- 制限中: 赤 `OAuth login restricted (primary email unverified)`
- 解除後: 緑 `OAuth login enabled — recovered #N`（登録済みの場合。未登録なら番号なし）

## 通し番号をもらう（回復したら）

制限中の記録を残したあとメール認証で解除し、バッジが緑になったら、
[登録 Issue](https://github.com/hydh/github-account-recovered-counter/issues/new?template=recovery-registration.md)
を作成してください。ワークフローが自動で:

- 名簿（registry.json）に **Issue 作者本人のログイン名**で通し番号を採番
- カウンターバッジ（counter.json）を更新
- 番号をコメントして Issue をクローズ

します。登録されるのは Issue を作った本人のアカウントなので、なりすましは
できません。二重登録は自動で弾かれます。

## 証明の仕組みと限界

- ワークフローが `GET /user/emails` を叩き、プライマリメールの `verified`
  フラグを確認します。
- 結果は `badge.json`（バッジ表示用）と `evidence.ndjson`（タイムスタンプ・
  状態・APIレスポンスの SHA-256・Actions 実行URL）にコミットされます。
- **制限中の状態で数回実行 → メール認証 → 再実行**とすることで、
  「restricted の記録」と「unrestricted の記録」が commit 履歴 + Actions ログの
  両方に残り、遷移を第三者に示せます。
- 限界: メール認証状態は公開 API に出ないため、完全に独立した第三者が
  リアルタイム検証できるものではありません（自分の Actions が観測者になる
  自己証明方式です）。公開リポジトリの Actions ログを誰でも閲覧できることが
  信頼性の担保です。名簿への登録も証跡リンクの提示は任意で、性善説ベースです。
- メールアドレス本体はログに含めません（ドメインのみ記録）。

## 解除の手順（参考）

GitHub の Settings → Emails で認証済みメールアドレスをプライマリに設定するか、
現在のプライマリメールに届く確認メールのリンクを踏んで認証すれば、
サードパーティ OAuth ログインの制限は即時解除されます。
