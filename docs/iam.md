# IAM permissions

The plugin itself calls no AWS API, so it needs no permissions of its own. Lambda's own permissions (logs, running in a VPC) are in [Serverless iam.md](https://redmine-kit.github.io/serverless/iam.html).

## Permissions

| Action | Resource | Why |
| --- | --- | --- |
| None | — | The "Status" tab and its connection test belong to [Redmine AWS](https://redmine-kit.github.io/redmine_aws/iam.html); the checks of S3, SES and SQS use the permissions on the IAM pages of those plugins |

## Example policy

None.

## Resource-based policies

None.

## Not checked yet

Nothing.
