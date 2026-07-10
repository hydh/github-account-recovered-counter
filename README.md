# github-account-recovered-counter

![GitHub account live](https://img.shields.io/website?url=https%3A%2F%2Fgithub.com%2Fhydh&up_message=unrestricted&down_message=restricted&up_color=brightgreen&down_color=red&label=GitHub%20account%20%40hydh)
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

制限には**誰でもリアルタイムに検証できるシグナル**があります: 制限
（シャドウバン）中のアカウントは、プロフィールやリポジトリなど公開コンテンツ
すべてが未認証アクセスに対して **404** を返します。これを利用した
**ライブバッジ**が最も強い証明です:

```markdown
![GitHub account live](https://img.shields.io/website?url=https%3A%2F%2Fgithub.com%2FUSER&up_message=unrestricted&down_message=restricted&up_color=brightgreen&down_color=red&label=GitHub%20account%20%40USER)
```

shields.io 自身が `https://github.com/USER` を観測して 404 なら赤
`restricted`、200 なら緑 `unrestricted` を描画します。トークン不要・
自己申告なしで、閲覧のたびに現在の状態が検証されます。ブログや外部サイト
など、どこにでも貼れます（制限中は GitHub 上の README 自体が第三者から
見えないため、外部に貼ることに意味があります）。

履歴（いつ制限され、いつ回復したか）の証明は2段構えです。制限中は
Actions が動かせないためです。

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

- 制限中は、このリポジトリ自体（証跡ログを含む）が第三者から見えません。
  リポジトリ内の証跡が公開監査可能になるのは回復後です。制限中に第三者へ
  状態を示せるのはライブバッジのみです。
- 制限中の観測はローカル実行のため、証跡の生成過程そのものは自己管理下に
  あります。信頼性の担保は「GitHub が返す 422 エラーの記録」「解除後に初めて
  Actions 実行が成功するという GitHub 側の公開記録」です。
- 名簿への登録は証跡リンクの提示が任意で、性善説ベースです。

## 解除の手順（参考）

制限の原因により異なりますが、認証済みの非フリーメールアドレスを
プライマリに設定する（Settings → Emails）、または GitHub サポートに
問い合わせることで解除できます。
