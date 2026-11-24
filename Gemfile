# frozen_string_literal: true

# Loaded by Redmine's Gemfile when the plugin is a checkout in plugins/. The
# plugin needs no gems of its own. To load boot/redmine_kit_aws_lambda.rb (the
# /events middleware), add the plugin as a gem by path in Gemfile.local
# (docs/setup.md#installation).

# A checkout in Redmine's plugins/: the plugin as a gem by its path, so that
# Bundler loads boot/redmine_kit_aws_lambda.rb before Rails initializes, as the installed gem
# does (Redmine runs init.rb too late for what boot/ sets), and Redmine Kit
# AWS, which its gemspec requires, from its checkout next to it; each unless
# Gemfile.local or another plugin's Gemfile names it already.
unless dependencies.any? { |dependency| dependency.name == 'redmine_kit_aws' }
  gem 'redmine_kit_aws', path: File.expand_path('../redmine_kit_aws', __dir__), require: false
end
unless dependencies.any? { |dependency| dependency.name == 'redmine_kit_aws_lambda' }
  gem 'redmine_kit_aws_lambda', path: __dir__
end
