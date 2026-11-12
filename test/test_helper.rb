# frozen_string_literal: true

# Coverage of the plugin's own files (bin/test sets PLUGIN_COVERAGE for the
# plugin's tests), written as Cobertura XML to coverage/ for Codecov. It starts
# before Redmine loads, so that boot/, lib/ and app/ are counted.
if ENV['PLUGIN_COVERAGE']
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    add_filter '/test/'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

require File.expand_path('../../../test/test_helper', __dir__)
require File.join(Redmine::Plugin.find(:redmine_aws).directory, 'test/support/redmine_aws/test_helper')

module RedmineAws
  module Lambda
    module TestHelper
      include RedmineAws::TestHelper

      # Runs the block as on Lambda (REDMINE_ROLE set), or without the role.
      def with_role(role, &)
        with_env({ 'REDMINE_ROLE' => role }, &)
      end

      # Runs the block as in a process started on Lambda: with the role, and
      # with what Settings.install does at start-up then (the repository types
      # other than Settings::SCM removed). Redmine's list is restored after.
      def on_lambda(role = 'web')
        saved = Redmine::Scm::Base.all.dup
        with_role(role) do
          Settings.install
          yield
        end
      ensure
        Redmine::Scm::Base.instance_variable_set(:@scms, saved)
      end
    end
  end
end
