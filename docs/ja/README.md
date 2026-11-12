# Redmine AWS Lambda

Redmine AWS Lambda (`redmine_aws_lambda`) は、Redmine を AWS Lambda で動かすための Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/architecture.html) が、Lambda 用のイメージにインストールして使います。「AWS」の管理メニューと「ステータス」のタブを持つ [Redmine AWS](https://redmine-kit.github.io/redmine_aws/ja/) を必要とします。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は開発の初期です。

- [導入](setup.md): 動作環境、インストール、設定、AWS リソース、ネットワーク、テスト
- [IAM 権限](iam.md): 権限、ポリシーの例、リソースベースのポリシー
- [管理画面](admin.md): ステータスのタブの Lambda 関数、Lambda で使えない Redmine の設定
- [Lambda で動かすとき](#running-on-lambda): `/events`、転送されたホスト、アセットの確認、テスト

<a id="features"></a>

## 機能

Redmine の標準の動きをできるだけ保ち、自前で書くのは、Lambda で動かすのに必要な部分だけにします。機能ごとに、有効にする条件を持たせます。条件がそろわない機能は、Redmine の標準のままに動きます。

| 機能 | 内容 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| Lambda での実行 | Lambda Web Adapter の `/events` に 204 を返す Rack のミドルウェア、CloudFront の `X-Forwarded-Host` を `Host` にする Rack のミドルウェア、アセットの自動の書き出しを止める設定、Lambda で使えない Redmine の設定を無効に固定して画面に表示する | `REDMINE_ROLE` がある | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| 管理画面 | Redmine AWS の「ステータス」のタブの Lambda 関数と読み取り専用の設定 | システム管理者 | [admin.md](admin.md) |

AWS のためのほかの機能は、別のプラグインです。Lambda 以外でも動きます。

| プラグイン | 内容 |
| --- | --- |
| [Redmine AWS S3](https://redmine-kit.github.io/redmine_aws_s3/ja/) | S3 の添付ファイル。署名付き URL で CloudFront を通すアップロードとダウンロード、`/tmp` のキャッシュ |
| [Redmine AWS SES](https://redmine-kit.github.io/redmine_aws_ses/ja/) | SES でのメール。エラーの種類別の再送信、受信と取り込み、プロジェクト別のアドレス |
| [Redmine AWS SQS](https://redmine-kit.github.io/redmine_aws_sqs/ja/) | SQS でのジョブ。`aws-activejob-sqs` の設定、ジョブの失敗の記録、再送信 |
| [Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) | SSM Parameter Store の設定とシークレット。Rails が起動する前に読み込む |

これらのプラグインは、Redmine AWS が持つ管理メニューの 1 つの項目「AWS」の下に、管理画面を 1 つのページのタブとして置きます ([Redmine AWS の admin.md](https://redmine-kit.github.io/redmine_aws/ja/admin.html#the-aws-menu))。それぞれの確認は、その接続テストに加わります。

<a id="code-layout"></a>

## コード構成

Rails の初期化より前に必要なもの (`/events` と転送されたホストのミドルウェア、アセットの設定) は、`boot/redmine_aws_lambda.rb` にあります。プラグインは gem でもあるので、Bundler がこのファイルを読み込みます ([setup.md](setup.md#installation))。ほかは Redmine が読み込む `lib/redmine_aws/lambda.rb`、`lib/redmine_aws/lambda/`、`app/` にあり、`init.rb` が有効にして、「ステータス」のタブの項目を追加します。コードは Redmine AWS の名前空間 `RedmineAws` の下の `RedmineAws::Lambda` で、`boot/` には `RedmineAws::Lambda::Boot` があります。

プラグインは自分では AWS の API を呼ばないので、AWS SDK の gem は不要です。データベースのテーブルも追加しないので、実行する migration はありません。差し替えた処理ごとに、Redmine の標準の仕組み (`rake redmine:plugins:test`) でテストを書いています ([setup.md](setup.md#tests))。

<a id="running-on-lambda"></a>

## Lambda で動かすとき

Lambda 上 (`REDMINE_ROLE` があるとき) では、プラグインが Redmine を次のように合わせます。イメージと関数は、[Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html) にあります。

| 何を | どうする | 理由 |
| --- | --- | --- |
| `/events` | ミドルウェアの並びの先頭の Rack のミドルウェア (`boot/` が登録する) が、データベースやセッションに触れる前に、`/events` に 204 を返す。ほかのパスはそのまま通す | Lambda Web Adapter は、関数 URL を通らないイベント (ウォームアップなど) を、`/events` への POST として Puma に渡す (`AWS_LWA_PASS_THROUGH_PATH`)。このパスには、CloudFront と関数 URL を通して、どのビューワーもどのメソッドでもアクセスでき、同じ空の 204 が返る。ミドルウェアはパスだけを読むので、リクエストは Redmine にもデータベースにも届かず、何も変更しない。応答するのは `/events` だけで、`/events/` や `/events.json` は Redmine に渡る。ロールがなければ、`/events` は通常のパス (404) |
| 転送されたホスト | `/events` のすぐ後の Rack のミドルウェア (`boot/` が登録する) が、Rails のホストの認可より前に、`X-Forwarded-Host` の最後の値を `Host` に入れる。`X-Forwarded-Host` がなければ `Host` はそのまま | リクエストは CloudFront と関数 URL を通り、`Host` は関数 URL 自身のホスト名になる。関数 URL とオリジンアクセスコントロールにはそれが必要。CloudFront は Redmine のドメインを `X-Forwarded-Host` で渡す。これはオリジンのカスタムヘッダーで、ビューワーが送った同じ名前のヘッダーを置き換える。Rails のホストの認可は、`Host` と `X-Forwarded-Host` のどちらかが `config.hosts` になければリクエストをブロックし、Lambda の `config.hosts` はドメインだけ ([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html#host-and-scheme))。そのため関数 URL のホスト名は受け付けない。`X-Forwarded-Host` がないか、ほかのホストが入ったリクエストは 403 でブロックされる |
| アセットの確認 | `config.assets.redmine_detect_update` を `false` にする。`boot/` が `after_initialize` で設定し、Redmine 自身の確認より前に動く | `production.rb` は `true` にし、Redmine は起動のときに古いアセットを `public/assets` に書き出す。Lambda ではファイルシステムが読み取り専用で、イメージにはビルドしたアセットがある |
| 使えない Redmine の設定 | 無効に固定し、設定の画面に表示する | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |

<a id="tests"></a>

### テスト

| 対象 | 確認すること |
| --- | --- |
| `/events` | どのメソッドでも、どの `Host` でも、SQL もセッションの Cookie もなしに 204 を返す。`/events/` や `/events.json` を含め、ほかのパスは通す。ロールがなければ 404。ミドルウェアは先頭にある |
| 転送されたホスト | ドメインだけを許す Rails のホストの認可の前に置き、`Host` に関数 URL のホスト名を入れたリクエストを送る。`X-Forwarded-Host` にドメインがあれば 200 で、URL もドメインで作る。値が複数なら最後の値を使う。`X-Forwarded-Host` がない、ほかのホスト、関数 URL のホスト名なら 403。ロールがなければ 403 (Rails の標準の動作)。ミドルウェアは `/events` のすぐ後にある |
| アセットの確認 | `REDMINE_ROLE` のある新しいプロセスで `false`。ロールがなければ変わらない |
| 固定する設定 | Lambda では読み出しが固定の値を返し、保存しても変わらない。ロールがなければ Redmine の標準のまま。設定の画面は、それらのチェックボックスを押せない状態にして注記を添え、Subversion と Git だけを表示する。ほかのチェックボックスは Redmine の表示のまま。ほかのリポジトリの種類は Lambda 上でだけ Redmine の一覧から外す |
| 差し替えたコード | Redmine の `Setting.define_setting` と `SettingsHelper#setting_check_box` の SHA-256 を比べ、Redmine のバージョンアップで変わったら気づけるようにする |
| ステータスのタブ | Redmine AWS のタブの Lambda 関数と読み取り専用の設定。タブの項目の間の順序。ロールがなければデータなし |
| コードの読み込み | 新しいプロセスで確認する。`zeitwerk:check` が通る。boot のファイルを読み込んだ状態で、Redmine AWS とこのプラグインが起動する |

<a id="sponsors"></a>

## スポンサー

<Sponsors ids="keyselect"><a href="https://www.keyselect.co.jp/">KEY SELECT</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine AWS Lambda は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
