# github-account-recovered-counter

![recovered accounts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/hydh/github-account-recovered-counter/main/counter.json)
![GitHub account](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/hydh/github-account-recovered-counter/main/badge.json)

GitHub はフリーメール／使い捨てドメインのプライマリメールアドレスなどを理由に
アカウントレベルの制限をかけることがあります。制限中のアカウントは:

- サードパーティサービスへの GitHub OAuth ログインが拒否される
- **GitHub Actions 自体が無効化される**（workflow dispatch が HTTP 422
  `Actions has been disabled for this user.` で拒否される）

このリポジトリは後者を**機械観測可能な制限シグナル**として利用し:

1. 「制限中 → 解除済み」の遷移を git 履歴と Actions 実行履歴に
   証跡として残す**バッジ**を提供します
2. 同じ仕組みで回復した全ユーザーを**通し番号付きでカウントする名簿**
   （[registry.json](registry.json)）を管理します

## 証明の設計

制限中は Actions が動かせないため、観測は2段構えです。

- **制限中（ローカル観測）**: [scripts/check-local.sh](scripts/check-local.sh) を
  ローカルで実行します。workflow dispatch を試行し、GitHub が返す 422 エラーを
  そのまま `evidence.ndjson` に記録します（GitHub 側の応答であり、自己申告では
  ありません）。バッジは赤 `restricted — Actions & OAuth disabled` になります。
- **解除後（Actions 観測）**: 制限が解除されると Actions が有効化され、
  ワークフロー
  [check-account-restriction.yml](.github/workflows/check-account-restriction.yml)
  が観測を引き継ぎます。**このリポジトリで最初に Actions の実行が成功した
  日時**が GitHub のサーバー記録として公開されるため、「それ以前は Actions を
  動かせなかった」ことと合わせて解除の時点を裏付けます。バッジは緑
  `unrestricted — recovered #N` になります。

補助証跡として、メールの認証状態（`GET /user/emails` の verified フラグ）も
記録します。メールアドレス本体はログに含めません（ドメインのみ記録）。

## 自分のバッジを作る

1. このリポジトリを**フォーク**する（public のまま。バッジを外部参照するため）。
2. classic PAT を `user:email` スコープ**のみ**で発行し、フォークの
   Settings → Secrets and variables → Actions に `EMAIL_CHECK_PAT` として登録する。
3. 制限中の間、ローカルで観測を実行して証跡を残す:

   ```sh
   gh auth refresh -h github.com -s user:email
   ./scripts/check-local.sh
   ```

4. 制限が解除されたら再度 `./scripts/check-local.sh` を実行する。dispatch が
   成功して Actions 側のワークフローが起動し、以降は毎日自動観測される。
5. README 等にバッジを貼る（`USER` を自分のログイン名に置き換え）:

   ```markdown
   ![GitHub account](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/USER/github-account-recovered-counter/main/badge.json)
   ```

## 通し番号をもらう（回復したら）

制限中の記録を残したあと制限を解除し、バッジが緑になったら、
[登録 Issue](https://github.com/hydh/github-account-recovered-counter/issues/new?template=recovery-registration.md)
を作成してください。ワークフローが自動で:

- 名簿（registry.json）に **Issue 作者本人のログイン名**で通し番号を採番
- カウンターバッジ（counter.json）を更新
- 番号をコメントして Issue をクローズ

します。登録されるのは Issue を作った本人のアカウントなので、なりすましは
できません。二重登録は自動で弾かれます。

## 限界

- 制限中の観測はローカル実行のため、証跡の生成過程そのものは自己管理下に
  あります。信頼性の担保は「GitHub が返す 422 エラーの記録」「解除後に初めて
  Actions 実行が成功するという GitHub 側の公開記録」の2点です。
- 名簿への登録は証跡リンクの提示が任意で、性善説ベースです。

## 解除の手順（参考）

制限の原因により異なりますが、認証済みの非フリーメールアドレスを
プライマリに設定する（Settings → Emails）、または GitHub サポートに
問い合わせることで解除できます。
