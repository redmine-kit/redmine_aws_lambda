# 導入

Redmine Kit AWS Lambda を使う Redmine に必要なもの (インストール、設定、前提とする AWS リソース、IAM 権限、ネットワーク) です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作成します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- PostgreSQL を使う Redmine 7.0 以降。
- `plugins/redmine_kit_aws` の [Redmine Kit AWS](https://redmine-kit.github.io/redmine_aws/ja/) 0.1 以降 ([その導入](https://redmine-kit.github.io/redmine_aws/ja/setup.html))。
- AWS Lambda では、[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#image) と同じく、Lambda Web Adapter を含むコンテナイメージ。Lambda 以外 (`REDMINE_ROLE` がないとき) では、プラグインの機能は無効で、Redmine は標準のまま動きます。

<a id="installation"></a>

## インストール

1. プラグインを Redmine 7.0 の `plugins/redmine_kit_aws_lambda` に、Redmine Kit AWS を `plugins/redmine_kit_aws` に置きます。下の gem か、それぞれのリポジトリのチェックアウトです。チェックアウトのディレクトリ名は、リポジトリ名ではなく、プラグインの ID にします (`git clone https://github.com/redmine-kit/redmine_aws_lambda.git plugins/redmine_kit_aws_lambda`、`git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws`)。
2. プラグインを gem として `Gemfile.local` に追加し、インストールします。

   ```sh
   bundle install
   ```

   こうすると、Bundler が、Rails の初期化より前に `boot/redmine_kit_aws_lambda.rb` を読み込みます。`/events` と転送されたホストのミドルウェア、アセットの設定はそのときまでに必要で、Redmine がプラグインを読み込む (`init.rb`) のでは間に合わないからです。チェックアウトなら、両方をパスで追加します。Redmine Kit AWS は、プラグインの gemspec が必要とするので追加します。Bundler は読み込みません (読み込むのは Redmine です)。ほかの Redmine Kit AWS のプラグインをパスで追加するときも、`redmine_kit_aws` の行は 1 つだけにします。

   ```ruby
   # Redmine の Gemfile.local
   gem 'redmine_kit_aws', path: 'plugins/redmine_kit_aws', require: false
   gem 'redmine_kit_aws_lambda', path: 'plugins/redmine_kit_aws_lambda'
   ```

3. migration は不要です。

<a id="gem"></a>

### gem

バージョンのタグ (`v*`) ごとに、プラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`) に公開します (`.github/workflows/gem.yml`)。gem には、実行に必要なファイル (`init.rb`、`boot/`、`lib/`、`app/`、`config/`、`help/`、`LICENSE`) が入ります。プラグインの `Gemfile` は入れません。gem は Redmine Kit AWS の gem に依存するので、Bundler がいっしょにインストールします。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした gem をそこにリンクします。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_aws_lambda'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <ユーザー>:<トークン>   # か、変数 BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_kit_aws)" plugins/redmine_kit_aws
ln -s "$(bundle info --path redmine_kit_aws_lambda)" plugins/redmine_kit_aws_lambda
```

GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが必要です。ほかのリポジトリのワークフローは、パッケージの設定 (「Manage Actions access」) でそのリポジトリに Read を与えると、自分の `GITHUB_TOKEN` (`packages: read`) で読めます。

Bundler は、それぞれのリポジトリからもプラグインをインストールできます。この場合、トークンは不要です。`plugins/` へのリンクは上と同じです。

```ruby
# Redmine の Gemfile.local
gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', tag: 'v0.1.0', require: false
gem 'redmine_kit_aws_lambda', git: 'https://github.com/redmine-kit/redmine_aws_lambda.git', tag: 'v0.1.0'
```

<a id="configuration"></a>

## 設定

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `REDMINE_ROLE` | Lambda のための機能を有効にする ([README.md](README.md#features)) | Lambda では必須。関数ごとに `web`、`worker`、`task` のどれか。なければ機能は無効 |

起動時に SSM Parameter Store から設定とシークレットを読み込むには、[Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) を使います。これをインストールすると、「ステータス」のタブに、読み込んだパラメーターの名前が表示されます。

<a id="aws-resources"></a>

## AWS リソース

| リソース | 設定 |
| --- | --- |
| Lambda 関数 | `REDMINE_ROLE` を設定し、Lambda Web Adapter で Redmine を動かす、コンテナイメージの関数 ([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html)) |

<a id="iam-permissions"></a>

## IAM 権限

プラグインに必要な権限とポリシーの例は、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 送信先 | API | インターネットに接続できない VPC では |
| --- | --- | --- |
| データベース | PostgreSQL (Redmine Kit AWS の「ステータス」のタブのデータベースの確認) | 関数からデータベースのポートへのセキュリティグループのルール |

<a id="tests"></a>

## テスト

テストは `test/` にあり、Redmine の標準の仕組みで、Redmine 7.0.3 と PostgreSQL 16 で実行します。Apple container がインストールされて動いていれば Apple container で、そうでなければ Docker で実行します (`CONTAINER_CLI=container` または `docker` で選べます)。1 台のマシンで同時に実行する redmine-kit のリポジトリのテストは 2 つまでで (`TEST_SLOTS`)、空きを待ってから始まります。`bin/test` は、このプラグインと Redmine Kit AWS (`../redmine_kit_aws`、または `REDMINE_KIT_AWS_DIR` のディレクトリ。CI は `redmine-kit/redmine_aws` をチェックアウトする) をインストールした Redmine をビルドし、プラグインのテストのあと、差し替えたコードに関係する Redmine 本体のテスト (設定、リポジトリ、`sys`、メールの受信、管理) を実行します。`bin/test --redmine` は、プラグインをインストールした状態で Redmine 本体のすべてのテストを実行します。CI はこちらを使い、静的チェックとテストを Ruby 3.2 と 4.0 で実行します。ローカルでは、`TEST_RUBY=3.2 bin/test` (または `bin/lint`) で Ruby 3.2 で実行します。

実行は、終わったときに (テストの成功、失敗、中断のいずれでも)、自分が起動したサービスのコンテナを停止します (削除はしません)。実行の前から動いていたコンテナと、このリポジトリの別の実行がまだ使っているコンテナは、そのまま動かしておきます。`KEEP_SERVICES=1` を指定すると、実行の後も動かしたままにします。

`COVERAGE=1` を付けると、プラグインのテストは、プラグイン自身のファイルのカバレッジ (SimpleCov。Cobertura の XML の `coverage/coverage.xml`) も出力し、1 プロセスで実行します。CI は Ruby 4.0 でこれを有効にし、レポートを `plugin` フラグで [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws_lambda) に送信します。送信の認証は OIDC (`id-token: write`) なので、トークンをシークレットに保存しません。Codecov のステータスは参考情報で、コミットや Pull Request を失敗にしません (`codecov.yml`)。

`bin/test-gem` は gem を確認します。チェックアウトからプラグインと Redmine Kit AWS の gem をビルドし、[gem](#gem) のとおりにインストールして `plugins/` にリンクし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と、起動時にすべてを読み込む production 環境)。CI もこれを実行するので、gem にないファイルがあれば、バージョンのタグで公開する前に失敗します。

```sh
bin/test            # プラグインのテストと、関係する Redmine のテスト
bin/test --redmine  # Redmine のすべてのテストも実行する
COVERAGE=1 bin/test # カバレッジを coverage/coverage.xml に出力する
bin/test-gem        # gem をビルド・インストールし、plugins/ にリンクして起動する
bin/lint            # RuboCop
bin/screenshots     # admin.md のスクリーンショット
bin/services --down # PostgreSQL を停止する
```

<a id="to-verify"></a>

## 未確認の事項

- AWS 上で、関数 URL が CloudFront の `X-Forwarded-Host` をそのまま関数に渡し、転送されたホストのミドルウェアに届くか。Lambda Web Adapter はリクエストヘッダーをそのまま Puma に渡します (1.1.0 のソースの `src/lib.rs`。2026-11-10 に確認)。関数 URL でのこのヘッダーの扱いは、Lambda のドキュメントにありません。
