# frozen_string_literal: true

# Redmine runs this when it prepares the code. The /events and forwarded host
# middlewares and the asset setting are in boot/redmine_aws_lambda.rb, which
# Bundler loads earlier.

# Redmine's code loader (Zeitwerk) skips lib/redmine_aws/lambda.rb when
# RedmineAws::Lambda is already defined, as it is when Bundler has loaded
# boot/redmine_aws_lambda.rb. The file is then loaded here.
require File.expand_path('lib/redmine_aws/lambda', __dir__) unless defined?(RedmineAws::Lambda::VERSION)

Redmine::Plugin.register :redmine_aws_lambda do
  # First, so that without redmine_aws Redmine stops with its own message
  # ("... requires the redmine_aws plugin") before anything else runs.
  requires_redmine_plugin :redmine_aws, version_or_higher: '0.1.0'
  name 'Redmine AWS Lambda'
  author 'Redmine Kit'
  description 'Runs Redmine on AWS Lambda'
  version RedmineAws::Lambda::VERSION
  url 'https://github.com/redmine-kit/redmine_aws_lambda'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineAws::Lambda.setup
