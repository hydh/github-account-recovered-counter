# github-account-recovered-counter

![recovered accounts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/hydh/github-account-recovered-counter/main/counter.json)
![GitHub account @hydh](https://img.shields.io/website?url=https%3A%2F%2Fgithub.com%2Fhydh&up_message=unrestricted&down_message=restricted&up_color=brightgreen&down_color=red&label=GitHub%20account%20%40hydh)

GitHub はフリーメール／使い捨てドメインのプライマリメールアドレスなどを理由に
アカウントレベルの制限をかけることがあります。制限中のアカウントは:

- サードパーティサービスへの GitHub OAuth ログインが拒否される
- 公開プロフィール・リポジトリが未認証アクセスに **404** を返す（シャドウバン）
- GitHub Actions 自体が無効化される（dispatch が HTTP 422
  `Actions has been disabled for this user.`）

このリポジトリは、その制限から回復したことを **GitHub ログインで本人確認しながら**
証明するバッジと、回復者を **通し番号付きでカウントする名簿**
（[registry.json](registry.json)）を提供します。

## 参加はフォーク不要。ボタン1つ。

👉 **[登録ページ](https://hydh.github.io/github-account-recovered-counter/)**（GitHub Pages）

または直接 **[登録 Issue を開く](https://github.com/hydh/github-account-recovered-counter/issues/new?template=recovery-registration.md&title=%5Brecovered%5D)**。

1. ボタンを押して Issue を送る（**GitHub ログインが必須**なので、この時点で本人確認済み）
2. Bot が数十秒であなた専用のバッジ Markdown と通し番号をコメントし、Issue を自動クローズ
3. もらった Markdown を README やブログに貼る

これだけです。フォークも Personal Access Token も Actions の設定もいりません。

## なりすましできない理由

- 登録の唯一の入り口は Issue の作成で、これは **GitHub にログインしていないと
  実行できません**。
- 採番 Bot はタイトルや本文の自由入力を**一切参照せず**、GitHub が検証した
  `issue.user.login`（本人のログイン名）だけで登録します。他人の名前で番号を
  取ることは原理的に不可能です。
- Bot は登録前に `github.com/あなた` が実際に **200** を返す（＝本当に制限解除
  済みで第三者から見える）ことを GitHub 側の生シグナルで確認します。まだ 404
  なら登録を拒否します。
- 発行されるバッジ Markdown は、その検証済みログインで固定されています
  （あなたが URL を手で書く箇所がないので、他人のアカウントを指すバッジを
  この経路で作ることはできません）。

> なぜ静的ページで「Sign in with GitHub」ボタンにしないのか: GitHub の OAuth は
> トークン交換に client secret を持つバックエンドが必須で、GitHub Pages のような
> 静的配信では安全に実装できません（デバイスフローもトークンエンドポイントが
> CORS を返さずブラウザから使えません）。そこで代わりに、**GitHub 認証済みの
> Issue／Actions フロー自体を本人確認の関門**として使っています。通し番号は
> 暗号的に検証された Issue 作者にのみ割り当てられ、自由入力では決して設定
> できないため、クライアント側 OAuth よりむしろ強い保証になります。

## バッジの仕組み

発行されるバッジはこの形式です（`USER` は検証済みのあなたのログインで固定）:

```markdown
![GitHub account](https://img.shields.io/website?url=https%3A%2F%2Fgithub.com%2FUSER&up_message=unrestricted&down_message=restricted&up_color=brightgreen&down_color=red&label=GitHub%20account%20%40USER)
```

shields.io 自身が `https://github.com/USER` を観測し、404 なら赤 `restricted`、
200 なら緑 `unrestricted` を描画します。トークン不要・自己申告なしで、閲覧の
たびに現在の状態がリアルタイム検証されます。制限が再発すれば自動で赤に戻ります。

## オプション：恒久的な証跡ログを残す（上級者向け）

ライブバッジは「今」の状態を示しますが、GitHub は「いつ制限され、いつ回復したか」
の履歴を公開しません。制限された日時・回復した日時のタイムスタンプ付きログを
自分の手元に残したい場合は、この方式を使います（**こちらはフォークが必要**）。

1. このリポジトリを**フォーク**する（public のまま）。
2. classic PAT を `user:email` スコープ**のみ**で発行し、フォークの
   Settings → Secrets and variables → Actions に `EMAIL_CHECK_PAT` として登録する。
3. 制限中の間、ローカルで観測を実行して証跡を残す（dispatch が返す 422 エラーごと
   [evidence.ndjson](evidence.ndjson) に記録される）:

   ```sh
   gh auth refresh -h github.com -s user:email
   ./scripts/check-local.sh
   ```

4. 制限が解除されたら再度 `./scripts/check-local.sh` を実行する。dispatch が
   成功して
   [check-account-restriction.yml](.github/workflows/check-account-restriction.yml)
   が起動し、**フォークで最初に Actions が成功した日時**が GitHub のサーバー
   記録として残る。以降は毎日自動観測される。

## 限界

- ライブバッジと名簿が証明するのは「**今**制限が解除されている」ことです。
  「過去に制限されていた」履歴は GitHub が公開しないため、独立した第三者が
  事後に完全検証することはできません（上級者向けの証跡ログで自己記録は可能）。
- 名簿への登録時、Bot は現在 200 が返ることは確認しますが、過去の制限有無までは
  検証できません。証跡リンクの提示は任意です。

## 解除の手順（参考）

制限の原因により異なりますが、認証済みの非フリーメールアドレスを
プライマリに設定する（Settings → Emails）、または GitHub サポートに
問い合わせることで解除できます。
