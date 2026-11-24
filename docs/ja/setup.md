# 導入

Redmine Kit AWS Lambda を使う Redmine に必要なもの (インストール、設定、前提とする AWS リソース、IAM 権限、ネットワーク) です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作成します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- PostgreSQL を使う Redmine 7.0 以降。
- AWS Lambda では、[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#image) と同じく、Lambda Web Adapter を含むコンテナイメージ。Lambda 以外 (`REDMINE_ROLE` がないとき) では、プラグインの機能は無効で、Redmine は標準のまま動きます。

<a id="required-plugins"></a>

### 必須プラグイン

| プラグイン | 用途 |
| --- | --- |
| [Redmine Kit AWS](https://github.com/redmine-kit/redmine_aws) | 「AWS」の管理メニューと、AWS のプラグインが共有する設定 |

ないときは、Redmine が起動時に停止し、そのプラグインの名前を示します。gem としてインストールすると、このプラグインがそれもインストールします ([インストール](#installation))。

<a id="optional-plugins"></a>

### オプションのプラグイン

| プラグイン | 使える機能 |
| --- | --- |
| [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) | ヘルプのパネルに表示するこのプラグインのヘルプ |

<a id="installation"></a>

## インストール

1. プラグインを gem としてインストールするか ([gem](#gem))、プラグインと、これが必要とする [Redmine Kit AWS](https://redmine-kit.github.io/redmine_aws/ja/) のチェックアウトを Redmine の `plugins/` に置きます ([gem を使わないとき](#without-the-gem))。順序は問いません。`redmine_kit_aws` がないときは、Redmine が起動時に停止し、その名前を示します ([必須プラグイン](#required-plugins))。
2. Redmine のフォルダーで `bundle install` を実行します。
3. マイグレーションは不要です。
4. Redmine を再起動します。

<a id="gem"></a>

### gem

**gem として** (推奨): Redmine の `Gemfile.local` に、GitHub Packages にある Redmine Kit のレジストリ (`https://rubygems.pkg.github.com/redmine-kit`。`bin/release` が公開します: [リリース](#releasing)) のブロックで追加します。このプラグインが必要とするプラグイン ([必須プラグイン](#required-plugins)) も Bundler がそこから取得し、これらの gem を rubygems.org から取得することはありません。レジストリには、公開のパッケージでも `read:packages` を持つ GitHub のトークンが必要です。Bundler には環境変数 `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` (`<user>:<token>`) で渡し、リポジトリのファイルには書きません。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_aws_lambda'
end
```

**リポジトリから** (開発用): Bundler は gem を git から取得します。Bundler は gem が必要とするプラグインを git からは取得しないので、その行も追加します。

```ruby
# Redmine の Gemfile.local
gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', branch: 'main'
gem 'redmine_kit_aws_lambda', git: 'https://github.com/redmine-kit/redmine_aws_lambda.git', branch: 'main'
```

Bundler が `boot/redmine_kit_aws_lambda.rb` を読み込み、gem のフォルダーと、依存する gem の Redmine Kit AWS のフォルダーを Redmine のプラグインローダーに渡します。Redmine は `plugins/` のプラグインと同じく、gem の `init.rb` を実行し、アセット、文字列、ビュー、マイグレーションを使い、`lib/` と `app/` を Rails のコードローダーに追加し、ルートを追加するので、`plugins/` へのリンクは不要です。`plugins/` に同じ id のフォルダーがあれば、そちらが優先されます。 このファイルは、Rails の初期化より前に必要なことも行います。`/events` と転送されたホストのミドルウェア、アセットの設定はそのときまでに必要で、Redmine が `init.rb` を実行するのでは間に合わないからです。 gem には実行に必要なファイルが入り、プラグインの `Gemfile` は入りません。

<a id="without-the-gem"></a>

### gem を使わないとき

リポジトリを Redmine の `plugins/` にクローンします。フォルダー名は、リポジトリ名ではなく、プラグインの ID にします。

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws
git clone https://github.com/redmine-kit/redmine_aws_lambda.git plugins/redmine_kit_aws_lambda
```

Redmine の `Gemfile` が読み込むプラグインの `Gemfile` が、プラグインをパスで指定するので、gem と同じく Bundler が Rails の初期化より前に `boot/redmine_kit_aws_lambda.rb` を読み込みます。隣のチェックアウトの Redmine Kit AWS もパスで指定します (どちらも、`Gemfile.local` かほかのプラグインの `Gemfile` がすでに指定していなければ)。`Gemfile.local` に行を追加する必要はありません。

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

`bin/test-gem` は、組織のプラグインのテンプレートと同じく gem を確認します。チェックアウトからプラグインと Redmine Kit AWS の gem をビルドし、チェックアウトを `plugins/` から外して [gem](#gem) のとおりにインストールし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と、起動時にすべてを読み込む production 環境)。各プラグインが gem のフォルダーから、boot のファイル、コード、ルート、マイグレーション、アセットとともに読み込まれることを確認し、チェックアウトを `plugins/` に戻して、チェックアウトが優先されることも確認します。。`bin/release` もこれを実行するので、gem にないファイルがあれば、リリースで公開する前に失敗します。

```sh
bin/test            # プラグインのテストと、関係する Redmine のテスト
bin/test --redmine  # Redmine のすべてのテストも実行する
COVERAGE=1 bin/test # カバレッジを coverage/coverage.xml に出力する
bin/test-gem        # gem をビルド・インストールし、gem から、次に plugins/ から起動する
bin/lint            # RuboCop
bin/screenshots     # admin.md のスクリーンショット
bin/services --down # PostgreSQL を停止する
```

<a id="releasing"></a>
## リリース

`bin/release` は、gemspec のバージョンの gem を GitHub Packages の Redmine Kit のレジストリに公開します。実行できるのは変更のない `main` からだけで、バージョンが最後のタグ `v<version>` より新しいこと、必須プラグインがレジストリから範囲どおりに解決できること (`config/dependencies.yml`)、`bin/lint`、`bin/test`、`bin/test-gem` が成功することが条件です。公開には `~/.gem/credentials` のキー `github` (`:github: Bearer <token>`。`write:packages` を持つトークン) を使い、レジストリの読み取りには `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` を使います。トークンはリポジトリにも出力にも含めません。署名付きのタグ `v<version>` を作り、それをプッシュするコマンドを表示します。バージョンはセマンティックバージョニングに従います。このプラグインを使うプラグインが動かなくなる変更ではメジャーバージョン (1.0 より前はマイナーバージョン) を上げ、それを必要とするプラグインの範囲も変えます。

<a id="to-verify"></a>

## 未確認の事項

- AWS 上で、関数 URL が CloudFront の `X-Forwarded-Host` をそのまま関数に渡し、転送されたホストのミドルウェアに届くか。Lambda Web Adapter はリクエストヘッダーをそのまま Puma に渡します (1.1.0 のソースの `src/lib.rs`。2026-11-10 に確認)。関数 URL でのこのヘッダーの扱いは、Lambda のドキュメントにありません。
