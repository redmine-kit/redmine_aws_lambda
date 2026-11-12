# Setup

What a Redmine server needs to use Redmine AWS Lambda: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later on PostgreSQL.
- [Redmine AWS](https://redmine-kit.github.io/redmine_aws/) 0.1 or later in `plugins/redmine_aws` ([its setup](https://redmine-kit.github.io/redmine_aws/setup.html)).
- On AWS Lambda: a container image with Lambda Web Adapter, as in [Serverless](https://redmine-kit.github.io/serverless/lambda.html#image). Outside Lambda (without `REDMINE_ROLE`), the plugin's features stay off and Redmine behaves as standard.

## Installation

1. Get the plugin into `plugins/redmine_aws_lambda` of Redmine 7.0, and Redmine AWS into `plugins/redmine_aws`: the gems below, or checkouts of the repositories.
2. Add the plugin to `Gemfile.local` as a gem, and install it:

   ```sh
   bundle install
   ```

   Bundler then loads `boot/redmine_aws_lambda.rb` before Rails initializes: the `/events` and forwarded host middlewares and the asset setting must be in place by then, and Redmine's own loading of plugins (`init.rb`) comes too late for them. With checkouts, add both by path; Redmine AWS is there because the plugin's gemspec requires it, and Bundler does not load it (Redmine does). List it once, however many Redmine AWS plugins are added by path:

   ```ruby
   # Redmine's Gemfile.local
   gem 'redmine_aws', path: 'plugins/redmine_aws', require: false
   gem 'redmine_aws_lambda', path: 'plugins/redmine_aws_lambda'
   ```

3. No migration is needed.

### Gem

Each version tag (`v*`) publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`; `.github/workflows/gem.yml`). The gem holds the run-time files (`init.rb`, `boot/`, `lib/`, `app/`, `config/`, `help/`, `LICENSE`); the plugin's `Gemfile` is not in it. It depends on the gem of Redmine AWS, which Bundler installs with it. Redmine loads plugins only from `plugins/`, so the installed gems are linked there:

```ruby
# Redmine's Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_aws_lambda'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <user>:<token>   # or BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_aws)" plugins/redmine_aws
ln -s "$(bundle info --path redmine_aws_lambda)" plugins/redmine_aws_lambda
```

Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. A workflow of another repository reads it with its `GITHUB_TOKEN` (`packages: read`) once the package's settings ("Manage Actions access") give that repository Read.

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_ROLE` | Turns on the features for Lambda ([README.md](README.md#features)) | Required on Lambda. Per function: `web`, `worker` or `task`. Without it, the features stay off |

To read settings and secrets from SSM Parameter Store at start-up, use [Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/). With it installed, the "Status" tab shows the names of the parameters read.

## AWS resources

| Resource | Settings |
| --- | --- |
| Lambda functions | Container image functions with `REDMINE_ROLE` set, running Redmine through Lambda Web Adapter ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html)) |

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database test on the "Status" tab of Redmine AWS) | A security group rule from the functions to the database port |

## Tests

The tests are in `test/` and run with Redmine's standard mechanism, in Redmine 7.0.3 on PostgreSQL 16 in Docker. `bin/test` builds Redmine with this plugin and Redmine AWS (from `../redmine_aws`, or the directory in `REDMINE_AWS_DIR`; CI checks out `redmine-kit/redmine_aws`) and runs the plugin's tests, then Redmine's own tests around the replaced code (settings, repositories, `sys`, incoming email, administration); `bin/test --redmine` runs every Redmine test with the plugin installed, as the CI does. CI runs the lint and the tests on Ruby 3.2 and 4.0; locally, `TEST_RUBY=3.2 bin/test` (or `bin/lint`) runs them on Ruby 3.2.

The plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`), which CI uploads to [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws_lambda).

`bin/test-gem` checks the gem: it builds the gems of the plugin and of Redmine AWS from the checkouts, installs them as [Gem](#gem) says, links them into `plugins/` and starts Redmine with every file loaded (`zeitwerk:check`, and the production environment, which loads them at start-up). CI runs it too, so a file missing from the gem fails before a version tag publishes it.

```sh
bin/test            # the plugin's tests and Redmine's tests around them
bin/test --redmine  # with every Redmine test
bin/test-gem        # the gem: built, installed, linked into plugins/, booted
bin/lint            # RuboCop
bin/screenshots     # the screenshots of admin.md
bin/services --down # stops PostgreSQL
```

## To verify

- On AWS, whether the function URL passes CloudFront's `X-Forwarded-Host` to the function unchanged, so that the forwarded host middleware gets it. Lambda Web Adapter passes the request headers to Puma as they are (its 1.1.0 source, `src/lib.rs`; checked on 2026-11-10); the function URL's handling of the header is not in Lambda's documentation.
