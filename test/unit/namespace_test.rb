# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'

module RedmineAws
  module Lambda
    # The plugin's code is under the RedmineAws namespace of redmine_aws
    # (lib/redmine_aws/lambda.rb), and its boot file defines
    # RedmineAws::Lambda::Boot before Redmine's code loader (Zeitwerk) starts,
    # as in the test image. Checked in new processes, as at start-up.
    class NamespaceTest < ActiveSupport::TestCase
      def rails(*)
        out, status = Open3.capture2e({ 'RAILS_ENV' => 'test' }, 'bin/rails', *, chdir: Rails.root.to_s)
        assert status.success?, out
        out
      end

      def test_zeitwerk_loads_every_file
        assert_includes rails('zeitwerk:check'), 'All is good!'
      end

      def test_both_plugins_start_with_the_boot_file_loaded
        script = 'print RedmineAws::VERSION, " ", RedmineAws::Lambda::VERSION, " ", ' \
                 'RedmineAws::Admin.status_sections.map(&:name).join(",")'

        assert_equal "#{RedmineAws::VERSION} #{VERSION} lambda_function,versions,loaded_settings,lambda_fixed_settings",
                     rails('runner', script).lines.last.to_s.strip
      end
    end
  end
end
