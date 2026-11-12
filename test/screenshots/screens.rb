# frozen_string_literal: true

require_relative '../test_helper'
require File.join(Redmine::Plugin.find(:redmine_aws).directory, 'test/support/redmine_aws/screenshot_case')

module RedmineAws
  module Lambda
    # The screens of docs/admin.md, on a function as Lambda sets it up (the
    # names and the image are examples).
    class ScreenshotsTest < ScreenshotCase
      self.docs = File.expand_path('../../docs', __dir__)

      LAMBDA = {
        'REDMINE_ROLE' => 'web',
        'AWS_LAMBDA_FUNCTION_NAME' => 'redmine-web',
        'AWS_LAMBDA_FUNCTION_VERSION' => '$LATEST',
        'AWS_LAMBDA_FUNCTION_MEMORY_SIZE' => '2048',
        'AWS_REGION' => 'ap-northeast-1',
        'REDMINE_IMAGE' => "111122223333.dkr.ecr.ap-northeast-1.amazonaws.com/redmine@sha256:#{'0f1e2d3c' * 8}"
      }.freeze

      def setup
        super
        @saved = LAMBDA.keys.index_with { |name| ENV.fetch(name, nil) }
        @scms = Redmine::Scm::Base.all.dup
        ENV.update(LAMBDA)
        Settings.install
      end

      def teardown
        @saved.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
        Redmine::Scm::Base.instance_variable_set(:@scms, @scms)
      end

      def test_screens
        each_language do |language|
          shoot_status(language)
          shoot_fixed_settings(language)
        end
      end

      private

      # Administration › AWS › Status, after the connection test.
      def shoot_status(language)
        visit '/admin/aws/status'
        click_link I18n.t(:button_test, locale: language)
        assert_selector 'table.list.checks'
        shoot 'status', language
      end

      # The Repositories tab of the settings, down to the box of fixed settings.
      def shoot_fixed_settings(language)
        visit '/settings?tab=repositories'
        assert_selector '#settings_autofetch_changesets[disabled]'
        box = "document.getElementById('settings_autofetch_changesets').closest('.box')"
        page.execute_script("#{box}.id = 'fixed-box'")
        hide_after '#fixed-box'
        shoot 'fixed-settings', language, selector: '#tab-content-repositories'
      end
    end
  end
end
