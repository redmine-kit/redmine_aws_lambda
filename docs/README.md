# Redmine AWS Lambda

Redmine AWS Lambda (`redmine_aws_lambda`) is a Redmine plugin for running Redmine on AWS Lambda. [Serverless](https://redmine-kit.github.io/serverless/architecture.html) installs it in the Lambda image. It requires [Redmine AWS](https://redmine-kit.github.io/redmine_aws/), which holds the "AWS" administration menu and the "Status" tab. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in early development.

- [Setup](setup.md): requirements, installation, configuration, AWS resources, network, tests
- [IAM permissions](iam.md): permissions, example policy, resource-based policies
- [Administration pages](admin.md): the Lambda function on the Status tab, Redmine settings that cannot work on Lambda
- [Running on Lambda](#running-on-lambda): `/events`, the forwarded host, asset detection, tests

## Features

The plugin keeps Redmine's standard behavior as far as possible and implements only what running on Lambda needs. Each feature has a condition that enables it. A feature whose conditions are not met behaves as standard Redmine.

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| Running on Lambda | A Rack middleware that returns 204 for Lambda Web Adapter's `/events`, a Rack middleware that makes CloudFront's `X-Forwarded-Host` the `Host`, a setting that stops automatic asset compilation, Redmine settings that cannot work on Lambda fixed to disabled and shown on screen | `REDMINE_ROLE` is set | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| Administration pages | The Lambda function and the read-only settings on the "Status" tab of Redmine AWS | Administrators | [admin.md](admin.md) |

The other features for AWS are separate plugins, which also work outside Lambda:

| Plugin | Contents |
| --- | --- |
| [Redmine AWS S3](https://redmine-kit.github.io/redmine_aws_s3/) | Attachments in S3: uploads and downloads through CloudFront with signed URLs, the `/tmp` cache |
| [Redmine AWS SES](https://redmine-kit.github.io/redmine_aws_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |
| [Redmine AWS SQS](https://redmine-kit.github.io/redmine_aws_sqs/) | Jobs on SQS: the settings of `aws-activejob-sqs`, job failure records, resending |
| [Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/) | Settings and secrets from SSM Parameter Store, read before Rails starts |

They put their administration pages under the one "AWS" item of Redmine's administration menu that Redmine AWS holds, as tabs of one page ([Redmine AWS admin.md](https://redmine-kit.github.io/redmine_aws/admin.html#the-aws-menu)), and their checks join its connection test.

## Code layout

What must be in place before Rails initializes (the `/events` and forwarded host middlewares and the asset setting) is in `boot/redmine_aws_lambda.rb`. Because the plugin is also a gem, Bundler loads this file ([setup.md](setup.md#installation)). The rest is in `lib/redmine_aws/lambda.rb`, `lib/redmine_aws/lambda/` and `app/`, which Redmine loads, and `init.rb` turns it on and adds the sections of the "Status" tab. The code is under the `RedmineAws` namespace of Redmine AWS: `RedmineAws::Lambda`, with `RedmineAws::Lambda::Boot` in `boot/`.

The plugin calls no AWS API itself, so it needs no AWS SDK gem. It adds no database tables, so there are no migrations to run. Each piece of replaced code has tests written with Redmine's standard mechanism (`rake redmine:plugins:test`) ([setup.md](setup.md#tests)).

## Running on Lambda

On Lambda (when `REDMINE_ROLE` is set), the plugin adapts Redmine as follows. [Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html) has the image and the functions.

| What | How | Why |
| --- | --- | --- |
| `/events` | A Rack middleware at the top of the stack (registered by `boot/`) answers `/events` with 204, before anything touches the database or a session. Other paths pass | Lambda Web Adapter passes events that do not come through the function URL (such as warming) to Puma as a POST to `/events` (`AWS_LWA_PASS_THROUGH_PATH`). The path can also be reached through CloudFront and the function URL by any viewer, with any method: such a request gets the same empty 204. The middleware reads only the path, so the request reaches neither Redmine nor the database and changes nothing. Only `/events` itself is answered; `/events/` or `/events.json` goes to Redmine. Without the role, `/events` is an ordinary path (404) |
| Forwarded host | A Rack middleware right after the `/events` one (registered by `boot/`), before Rails' host authorization, puts the last value of `X-Forwarded-Host` in `Host`. Without `X-Forwarded-Host`, `Host` stays as it is | Requests come through CloudFront and the function URL, and `Host` is the function URL's own host name, which the function URL and origin access control need. CloudFront passes the Redmine domain in `X-Forwarded-Host`, an origin custom header that replaces one sent by the viewer. Rails' host authorization blocks a request when either `Host` or `X-Forwarded-Host` is not in `config.hosts`, which on Lambda holds only the domain ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html#host-and-scheme)). So the function URL's host name is never accepted: a request without `X-Forwarded-Host`, or with another host in it, is blocked with 403 |
| Asset detection | `config.assets.redmine_detect_update` is `false`, set in `boot/` with `after_initialize`, which runs before Redmine's own check | `production.rb` sets it to `true`, and Redmine then writes outdated assets to `public/assets` at start-up. On Lambda the file system is read-only and the image has the assets compiled |
| Redmine settings that cannot work | Fixed to disabled and shown on the settings page | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |

### Tests

| Target | What is checked |
| --- | --- |
| `/events` | 204 without SQL and without a session cookie, for every method and any `Host`; other paths, including `/events/` and `/events.json`, pass; 404 without the role; the middleware is the first one |
| Forwarded host | In front of Rails' host authorization for the domain only, with the function URL's host name in `Host`: 200 with the domain in `X-Forwarded-Host`, and URLs built with it; the last of several values counts; 403 without `X-Forwarded-Host`, with another host or with the function URL's host name in it; 403 without the role (Rails' standard behavior); the middleware comes right after the `/events` one |
| Asset detection | `false` in a new process with `REDMINE_ROLE`, unchanged without it |
| Fixed settings | The readers return the fixed values on Lambda, saving does not change them, Redmine's standard behavior without the role; the settings page shows their checkboxes disabled with the note and lists only Subversion and Git, other checkboxes stay as Redmine shows them; the other repository types are removed from Redmine's list on Lambda only |
| The replaced code | The SHA-256 of `Setting.define_setting` and `SettingsHelper#setting_check_box` in Redmine is compared, so that an upgrade of Redmine that changes them is noticed |
| Status tab | The Lambda function and the read-only settings on Redmine AWS's tab, in order between its sections; no data without the role |
| Code loading | In new processes: `zeitwerk:check` passes, and Redmine AWS and this plugin start with the boot file loaded |

## Sponsors

<Sponsors><a href="https://www.keyselect.co.jp/">KEY SELECT</a> <a href="https://localstack.cloud">LocalStack</a></Sponsors>

## License

Redmine AWS Lambda is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](../LICENSE). An unofficial Redmine plugin.
