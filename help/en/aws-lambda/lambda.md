# Redmine on AWS Lambda

On AWS Lambda, Administration › AWS › **Status** also shows the Lambda function that serves the page (its name, role, version, memory, Region and image URI) and, under "Read-only settings", the Redmine settings that are fixed on Lambda, with their values.

The Redmine settings fixed on Lambda ("Fetch commits automatically", "Enable WS for repository management" and "Enable WS for incoming emails") are shown disabled in Administration › Settings, with the note "Can't be set in this environment", because they cannot work on Lambda. Only Subversion and Git are listed as repository types.

More: [Redmine AWS Lambda: administration pages](https://redmine-kit.github.io/redmine_aws_lambda/admin.html).
