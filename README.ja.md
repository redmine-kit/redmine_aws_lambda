# Redmine AWS Lambda

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws_lambda/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws_lambda/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws_lambda?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws_lambda)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws_lambda?label=License)](LICENSE)

Redmine を AWS Lambda で動かすための Redmine のプラグインです。Lambda Web Adapter の `/events`、CloudFront から転送されたホスト、Lambda で使えない Redmine の設定の固定と画面での表示、「ステータス」のタブの Lambda 関数を持ちます。[Serverless](https://github.com/redmine-kit/serverless) のプラグインです。「AWS」の管理メニューを持つ [Redmine AWS](https://github.com/redmine-kit/redmine_aws) を必要とします。添付ファイル、メール、ジョブ、Parameter Store の設定は、別のプラグインの [Redmine AWS S3](https://github.com/redmine-kit/redmine_aws_s3)、[Redmine AWS SES](https://github.com/redmine-kit/redmine_aws_ses)、[Redmine AWS SQS](https://github.com/redmine-kit/redmine_aws_sqs)、[Redmine AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm) です。

[English](README.md)

> **状態:** 開発の初期です。実装し、Redmine 7.0.3 でテストしています。

<a id="documentation"></a>

## ドキュメント

- Web サイト: https://redmine-kit.github.io/redmine_aws_lambda/ja/ (English: https://redmine-kit.github.io/redmine_aws_lambda/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))。[導入](docs/ja/setup.md)、[IAM 権限](docs/ja/iam.md)、[管理画面](docs/ja/admin.md) があります。

<a id="sponsors"></a>

## スポンサー

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>
&emsp;&emsp;
<a href="https://localstack.cloud">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/localstack-logo-dark.svg">
    <img alt="LocalStack" src=".github/assets/localstack-logo.svg" width="98" height="23">
  </picture>
</a>

<a id="license"></a>

## ライセンス

Redmine AWS Lambda は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine の非公式のプラグインです。
