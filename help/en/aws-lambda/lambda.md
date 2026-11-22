# Redmine on AWS Lambda

Redmine Kit AWS Lambda adapts Redmine to run on AWS Lambda. It is for system administrators: users see no difference. Its features are on only when the environment variable `REDMINE_ROLE` is set (`web`, `worker` or `task`), as it is on Lambda; otherwise Redmine works as usual. The plugin has no page of its own and calls no AWS API.

## What it changes

- Lambda Web Adapter's `/events` requests get an empty answer (204), and the host name that CloudFront forwards (`X-Forwarded-Host`) becomes the request's host.
- Assets are not compiled while Redmine runs.
- Redmine settings that cannot work on Lambda are fixed off (below).

## Where its status shows

**Administration** › **AWS** › **Status** (Redmine Kit AWS) shows:

- **Lambda function**: **Function name**, **Role** (the value of `REDMINE_ROLE`), **Version**, **Memory**, **Region** and **Image URI** of the function that served the page.
- **Read-only settings**: the Redmine settings fixed on Lambda, with their values.

**Versions** on the same tab lists the plugin with its version.

## Settings fixed on Lambda

On Lambda, these settings are always off, because Lambda cannot run what they need:

- **Fetch commits automatically** and **Enable WS for repository management** (**Administration** › **Settings** › **Repositories**)
- **Enable WS for incoming emails** (**Administration** › **Settings** › **Incoming emails**)

They are shown disabled, with the note "Can't be set in this environment". Values saved earlier stay in the database and are not used. **Enabled SCM** and the repository form offer only Subversion and Git, and the repository types built on them.
