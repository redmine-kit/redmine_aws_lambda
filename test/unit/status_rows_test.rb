# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Aws
    module Lambda
      # The sections this plugin adds to the Status tab as rows of values, as
      # both Redmine's page and the new UI's JSON (AwsStatusController#index)
      # take them from RedmineKit::Aws::Status#sections.
      class StatusRowsTest < ActiveSupport::TestCase
        include Lambda::TestHelper

        def sections
          RedmineKit::Aws::Status.new.sections(ApplicationController.new.view_context).index_by { |section| section[:name] }
        end

        def test_the_sections_are_values_in_their_order
          names = with_role('web') { sections.keys }

          assert_equal %w[lambda_function versions lambda_fixed_settings], names
        end

        def test_the_function_rows_are_formatted
          function = with_env('REDMINE_ROLE' => 'worker', 'AWS_LAMBDA_FUNCTION_NAME' => 'redmine-worker',
                              'AWS_LAMBDA_FUNCTION_MEMORY_SIZE' => '2048') { sections['lambda_function'] }

          assert_equal 'Lambda function', function[:label]
          assert_includes function[:rows], { name: 'Function name', value: 'redmine-worker' }
          assert_includes function[:rows], { name: 'Role', value: 'worker', note: 'REDMINE_ROLE' }
          assert_includes function[:rows], { name: 'Memory', value: '2,048 MB' }
          assert_includes function[:rows], { name: 'Version', value: '-' }
        end

        def test_the_fixed_settings_rows
          rows = with_role('web') { sections['lambda_fixed_settings'][:rows] }

          assert_equal Settings::FIXED.keys.map(&:to_s), rows.pluck(:note)
          assert_includes rows, { name: 'Enable WS for repository management', value: 'No', note: 'sys_api_enabled' }
        end

        def test_no_fixed_settings_off_lambda
          assert_equal [], with_role(nil) { sections['lambda_fixed_settings'][:rows] }
        end
      end
    end
  end
end
