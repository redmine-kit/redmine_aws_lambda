# frozen_string_literal: true

# The plugins this one requires (config/dependencies.yml): without one,
# Redmine stops here and names it.
load File.expand_path('config/dependencies.rb', __dir__)

# Redmine runs this when it prepares the code. The /events and forwarded host
# middlewares and the asset setting are in boot/redmine_kit_aws_lambda.rb, which
# Bundler loads earlier.

# Redmine's code loader (Zeitwerk) skips lib/redmine_kit/aws/lambda.rb when
# RedmineKit::Aws::Lambda is already defined, as it is when Bundler has loaded
# boot/redmine_kit_aws_lambda.rb. The file is then loaded here.
require File.expand_path('lib/redmine_kit/aws/lambda', __dir__) unless defined?(RedmineKit::Aws::Lambda::VERSION)

Redmine::Plugin.register :redmine_kit_aws_lambda do
  # This folder, as Redmine's plugin loader found it: plugins/redmine_kit_aws_lambda (a checkout
  # or a link), or the installed gem's folder (boot/redmine_kit_aws_lambda.rb). Redmine's
  # default is plugins/<id>, which a gem doesn't have.
  directory File.dirname(__FILE__)
  name 'Redmine Kit AWS Lambda'
  author 'Redmine Kit'
  description 'Runs Redmine on AWS Lambda'
  version RedmineKit::Aws::Lambda::VERSION
  url 'https://github.com/redmine-kit/redmine_aws_lambda'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineKit::Aws::Lambda.setup
