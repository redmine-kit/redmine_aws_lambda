# Redmine AWS Lambda

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws_lambda/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws_lambda/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws_lambda?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws_lambda)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws_lambda?label=License)](LICENSE)

A Redmine plugin for running Redmine on AWS Lambda: the Lambda Web Adapter `/events` endpoint, CloudFront's forwarded host, and Redmine settings that cannot work on Lambda fixed and shown on screen, with the Lambda function on the "Status" tab. It is the plugin of [Serverless](https://github.com/redmine-kit/serverless). It requires [Redmine AWS](https://github.com/redmine-kit/redmine_aws), which holds the "AWS" administration menu. Attachments, email, jobs and settings from Parameter Store are the separate plugins [Redmine AWS S3](https://github.com/redmine-kit/redmine_aws_s3), [Redmine AWS SES](https://github.com/redmine-kit/redmine_aws_ses), [Redmine AWS SQS](https://github.com/redmine-kit/redmine_aws_sqs) and [Redmine AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm).

[日本語](README.ja.md)

> **Status:** early development. It is implemented and tested on Redmine 7.0.3.

## Documentation

- Website: https://redmine-kit.github.io/redmine_aws_lambda/ (日本語: https://redmine-kit.github.io/redmine_aws_lambda/ja/)
- Markdown: [docs/README.md](docs/README.md) (日本語: [docs/ja/README.md](docs/ja/README.md)), with [setup](docs/setup.md), [IAM permissions](docs/iam.md) and the [administration pages](docs/admin.md)

## Sponsors

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>

## License

Redmine AWS Lambda is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](LICENSE). An unofficial Redmine plugin.
