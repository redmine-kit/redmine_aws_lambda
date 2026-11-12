# frozen_string_literal: true

require_relative '../test_helper'

module RedmineAws
  module Lambda
    # The sections this plugin adds to the Status tab of redmine_aws.
    class StatusSectionsTest < Redmine::ControllerTest
      include Lambda::TestHelper

      tests AwsStatusController

      # REDMINE_IMAGE as the deployment sets it (docs/admin.md#status).
      IMAGE = "111122223333.dkr.ecr.ap-northeast-1.amazonaws.com/redmine@sha256:#{'0f1e2d3c' * 8}".freeze

      def setup
        @request.session[:user_id] = 1 # admin
      end

      def test_the_function_on_lambda
        open_status_on_lambda

        assert_response :success
        assert_select 'h3', text: 'Lambda function'
        assert_select 'table.list.values tr', text: /Function name\s*redmine-web/
        assert_select 'table.list.values tr', text: /Role\s*web\s*REDMINE_ROLE/
        assert_select 'table.list.values tr', text: /Memory\s*2,048 MB/
        assert_select 'table.list.values tr', text: /Image URI\s*#{Regexp.escape(IMAGE)}/
        assert_select 'table.list.values td.name', text: 'Redmine AWS Lambda'
      end

      def test_the_fixed_settings_on_lambda
        open_status_on_lambda

        assert_response :success
        assert_select 'h3', text: 'Read-only settings'
        assert_select 'table.list.values tr', text: /Enable WS for repository management\s*No\s*sys_api_enabled/
        assert_select 'table.list.values tr em.info', text: 'enabled_scm', count: 0
      end

      def test_the_order_of_the_sections
        with_role('web') { get :index }

        headings = css_select('#content h3').map(&:text)

        assert_equal ['Lambda function', 'Versions', 'Read-only settings', 'Connection test'], headings
      end

      def test_without_the_role
        with_role(nil) { get :index }

        assert_response :success
        assert_select 'table.list.values tr', text: /Function name\s*-/
        assert_select 'p.nodata', text: 'No data to display'
      end

      private

      # The Status tab as a web function of Lambda shows it.
      def open_status_on_lambda
        with_env('REDMINE_ROLE' => 'web', 'AWS_LAMBDA_FUNCTION_NAME' => 'redmine-web',
                 'AWS_LAMBDA_FUNCTION_MEMORY_SIZE' => '2048', 'REDMINE_IMAGE' => IMAGE) do
          get :index
        end
      end
    end
  end
end
