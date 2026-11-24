# Setup

What a Redmine server needs to use Redmine Kit AWS Lambda: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later on PostgreSQL.
- On AWS Lambda: a container image with Lambda Web Adapter, as in [Serverless](https://redmine-kit.github.io/serverless/lambda.html#image). Outside Lambda (without `REDMINE_ROLE`), the plugin's features stay off and Redmine behaves as standard.

### Required plugins

| Plugin | Used for |
| --- | --- |
| [Redmine Kit AWS](https://github.com/redmine-kit/redmine_aws) | the AWS administration menu and the settings shared by the AWS plugins |

Without it, Redmine stops at boot and names it. Installed as a gem, this plugin installs it
([Installation](#installation)).

### Optional plugins

| Plugin | With it |
| --- | --- |
| [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) | this plugin's help in the Help panel |

## Installation

1. Install the plugin as a gem ([Gem](#gem)), or put checkouts of it and of [Redmine Kit AWS](https://redmine-kit.github.io/redmine_aws/), which it requires, in Redmine's `plugins/` ([Without the gem](#without-the-gem)). The order doesn't matter: at boot, Redmine stops and names `redmine_kit_aws` when it is missing ([Required plugins](#required-plugins)).
2. Run `bundle install` in Redmine's folder.
3. No migration is needed.
4. Restart Redmine.

### Gem

**As a gem** (first choice): add it to Redmine's `Gemfile.local`, in a block of Redmine Kit's registry on GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`, where `bin/release` publishes it: [Releasing](#releasing)). Bundler takes the plugins it requires from there too ([Required plugins](#required-plugins)), and never takes these gems from rubygems.org. The registry needs a GitHub token with `read:packages`, even for a public package, given to Bundler in the environment variable `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` (`<user>:<token>`), never in a file of a repository.

```ruby
# Redmine's Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_aws_lambda'
end
```

**From the repositories** (for development), Bundler takes the gems from git instead; it doesn't take the plugins a gem requires from git, so their lines come too:

```ruby
# Redmine's Gemfile.local
gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', branch: 'main'
gem 'redmine_kit_aws_lambda', git: 'https://github.com/redmine-kit/redmine_aws_lambda.git', branch: 'main'
```

Bundler requires `boot/redmine_kit_aws_lambda.rb`, which hands the gem's folder to Redmine's plugin loader (and, from the gems it depends on, Redmine Kit AWS's): Redmine runs the gem's `init.rb`, serves its assets, strings, views and migrations, adds its `lib/` and `app/` to Rails' code loader and draws its routes, as for a plugin in `plugins/`, so no link in `plugins/` is needed. A folder of the same id in `plugins/` wins over the gem. The file also does what must be in place before Rails initializes: the `/events` and forwarded host middlewares and the asset setting must be in place by then, and Redmine runs `init.rb` too late for them. The gem holds the run-time files; the plugin's `Gemfile` is not in it.

### Without the gem

Clone the repositories into Redmine's `plugins/`, in folders named after the plugins' ids, which differ from the repositories' names:

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws
git clone https://github.com/redmine-kit/redmine_aws_lambda.git plugins/redmine_kit_aws_lambda
```

The plugin's `Gemfile`, which Redmine's `Gemfile` loads, names the plugin by its path, so that Bundler loads `boot/redmine_kit_aws_lambda.rb` before Rails initializes as the gem's does, and Redmine Kit AWS by the path of its checkout next to it (each unless `Gemfile.local` or another plugin's `Gemfile` names it already). No line in `Gemfile.local` is needed.

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_ROLE` | Turns on the features for Lambda ([README.md](README.md#features)) | Required on Lambda. Per function: `web`, `worker` or `task`. Without it, the features stay off |

To read settings and secrets from SSM Parameter Store at start-up, use [Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/). With it installed, the "Status" tab shows the names of the parameters read.

## AWS resources

| Resource | Settings |
| --- | --- |
| Lambda functions | Container image functions with `REDMINE_ROLE` set, running Redmine through Lambda Web Adapter ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html)) |

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database test on the "Status" tab of Redmine Kit AWS) | A security group rule from the functions to the database port |

## Tests

The tests are in `test/` and run with Redmine's standard mechanism, in Redmine 7.0.3 on PostgreSQL 16, in Apple container when it is installed and running, else in Docker (`CONTAINER_CLI=container` or `docker` chooses). At most two test runs of the redmine-kit repositories run at once on a machine (`TEST_SLOTS`); a run waits for a free slot. `bin/test` builds Redmine with this plugin and Redmine Kit AWS (from `../redmine_kit_aws`, or the directory in `REDMINE_KIT_AWS_DIR`; CI checks out `redmine-kit/redmine_aws`) and runs the plugin's tests, then Redmine's own tests around the replaced code (settings, repositories, `sys`, incoming email, administration); `bin/test --redmine` runs every Redmine test with the plugin installed, as the CI does. CI runs the lint and the tests on Ruby 3.2 and 4.0; locally, `TEST_RUBY=3.2 bin/test` (or `bin/lint`) runs them on Ruby 3.2.

A run stops the service containers it started (it doesn't remove them) when it ends, whether the tests pass, fail or are interrupted. Containers that were running before the run, or that another run of this repository still uses, are left running. `KEEP_SERVICES=1` keeps them running after the run.

With `COVERAGE=1`, the plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`) and run in one process. CI sets it on Ruby 4.0 and uploads the report to [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws_lambda) with the flag `plugin`. The upload authenticates with OIDC (`id-token: write`), so no token is stored as a secret. Codecov's statuses are informational and never fail a commit or a pull request (`codecov.yml`).

`bin/test-gem` checks the gem as the template of the organization's plugins does: it builds the gems of the plugin and of Redmine Kit AWS from the checkouts, takes the checkouts out of `plugins/`, installs the gems as [Gem](#gem) says and starts Redmine with every file loaded (`zeitwerk:check`, and the production environment, which loads them at start-up), checking that each plugin comes from its gem's folder with its boot file, code, routes, migrations and assets; then again with the checkouts back in `plugins/`, which win. `bin/release` runs it too, so a file missing from the gem fails before a release publishes it.

```sh
bin/test            # the plugin's tests and Redmine's tests around them
bin/test --redmine  # with every Redmine test
COVERAGE=1 bin/test # with the coverage in coverage/coverage.xml
bin/test-gem        # the gems: built, installed, booted from the gems, then from plugins/
bin/lint            # RuboCop
bin/screenshots     # the screenshots of admin.md
bin/services --down # stops PostgreSQL
```

## Releasing

`bin/release` publishes the gem of the gemspec's version to Redmine Kit's registry on GitHub Packages, from a clean
`main` only: the version must be newer than the last tag `v<version>`, the required plugins must resolve from the
registry at their ranges (`config/dependencies.yml`), and `bin/lint`, `bin/test` and `bin/test-gem` must pass. It
pushes with the key `github` of `~/.gem/credentials` (`:github: Bearer <token>`, a token with `write:packages`) and
reads the registry with `BUNDLE_RUBYGEMS__PKG__GITHUB__COM`; no token goes into the repository or the output. It makes
the signed tag `v<version>` and prints the command that pushes it. Versions are semantic: a change that breaks a plugin
using this one raises the major version (the minor one before 1.0), and the ranges in the plugins that require it.

## To verify

- On AWS, whether the function URL passes CloudFront's `X-Forwarded-Host` to the function unchanged, so that the forwarded host middleware gets it. Lambda Web Adapter passes the request headers to Puma as they are (its 1.1.0 source, `src/lib.rs`; checked on 2026-11-10); the function URL's handling of the header is not in Lambda's documentation.
