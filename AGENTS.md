# AGENTS.md

Guidelines for people and coding agents working in this repository. See [README.md](README.md) for an overview and [docs/](docs/README.md) for the design.

## What this project does

Redmine AWS Lambda (`redmine_aws_lambda`) is a Redmine plugin for running Redmine on AWS Lambda. It is used by [Serverless](https://github.com/redmine-kit/serverless), which runs Redmine on AWS Lambda. It requires [redmine_aws](https://github.com/redmine-kit/redmine_aws), which holds the "AWS" administration menu, the Status tab and what the AWS plugins share. Attachments, email, jobs and settings from Parameter Store are separate plugins ([redmine_aws_s3](https://github.com/redmine-kit/redmine_aws_s3), [redmine_aws_ses](https://github.com/redmine-kit/redmine_aws_ses), [redmine_aws_sqs](https://github.com/redmine-kit/redmine_aws_sqs), [redmine_aws_ssm](https://github.com/redmine-kit/redmine_aws_ssm)). It is in early development.

## Rules

- **Redmine's extension points only:** do not edit Redmine's own files. Keep Redmine's standard behaviour wherever possible, and write only what running on Lambda needs.
- **Features can be turned on separately:** each feature has the condition that turns it on; without it, Redmine behaves as standard.
- **Replaced code:** the plugin replaces only the readers of the settings that cannot work on Lambda ([admin.md](docs/admin.md#redmine-settings-that-cannot-work-on-lambda)). When Redmine is upgraded, check that the original code has not changed.
- **Shared parts in redmine_aws:** the administration menu, the Status tab and the test support come from redmine_aws ([its API](https://github.com/redmine-kit/redmine_aws/blob/main/docs/api.md)). What every AWS plugin needs goes there, not here.
- **Tests:** replaced and added code has tests, run with Redmine's own mechanism (`bin/test` runs them in Docker with redmine_aws from `../redmine_aws` or `REDMINE_AWS_DIR`; [setup.md](docs/setup.md#tests)). The test plan is in Serverless ([testing.md](https://github.com/redmine-kit/serverless/blob/main/docs/testing.md#plugin-tests)).
- **Code layout:** the code is under the `RedmineAws` namespace of redmine_aws, as `RedmineAws::Lambda`. `boot/redmine_aws_lambda.rb` holds what must be in place before Rails initializes (Bundler loads it; it requires `redmine_aws/inflections` first and defines module `RedmineAws::Lambda::Boot`, and nothing else in the namespace), `lib/redmine_aws/lambda.rb` and `lib/redmine_aws/lambda/` and `app/` the rest (Redmine autoloads them; `init.rb` loads `lib/redmine_aws/lambda.rb` when the code loader skipped it and calls `RedmineAws::Lambda.setup`). Inside the namespace, write the AWS SDK as `::Aws::…`.
- **No secrets in the repository.**

## Documentation

- **Two languages.** English is the source (`README.md`, `docs/`); the Japanese translation is `README.ja.md` and `docs/ja/`, with the same file names. Change both together.
- **Layout.** The READMEs stay short. The details go in `docs/`, published at https://redmine-kit.github.io/redmine_aws_lambda/ with [redmine-kit/docs-skeleton](https://github.com/redmine-kit/docs-skeleton). `docs/README.md` has the overview and the features, `docs/setup.md` the sections Requirements, Installation, Configuration, AWS resources, IAM permissions, Network, Tests and To verify, in this order (the same in every Redmine AWS plugin; IAM permissions there is one line that points to `docs/iam.md`), `docs/iam.md` the sections Permissions, Example policy, Resource-based policies and Not checked yet. Links to the documentation of Serverless and the other plugins are absolute URLs of their documentation sites (`https://redmine-kit.github.io/<repository>/`, `.../ja/` for Japanese).
- **Anchors in Japanese.** Put `<a id="..."></a>` with the English heading's anchor before each Japanese heading.
- **Facts.** State only what has been checked, with the date and the source. Mark what has not been checked yet.
- **Japanese wording.** Follow the organization's rules (`../AGENTS.md`): plain, precise Japanese with established technical terms, half-width parentheses with a space around them, "バージョン" rather than "版", "通知" rather than "知らせ", "確認" rather than "確かめ", "インストール" rather than "入れ方".

## Commits

- English, imperative mood, 72 characters or fewer in the first line, no trailing period.
- One purpose per commit.
- Do not rewrite pushed history.
