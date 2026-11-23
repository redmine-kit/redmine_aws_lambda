# frozen_string_literal: true

module RedmineKit
  module Aws
    # Running Redmine on AWS Lambda (docs/README.md). The features are on only
    # when REDMINE_ROLE is set (web, worker or task), as on Lambda. What must be
    # in place before Rails initializes is in boot/redmine_kit_aws_lambda.rb.
    module Lambda
      VERSION = '0.1.0'

      def self.role
        ENV.fetch('REDMINE_ROLE', '').presence
      end

      def self.lambda?
        role.present?
      end

      # Called from init.rb, on every code reload.
      def self.setup
        Settings.install
        Admin.register_status_section(:lambda_function, label: :label_aws_lambda_function, position: 10) do |view, _|
          Status.function_rows(view)
        end
        Admin.register_status_section(:lambda_fixed_settings, label: :label_aws_lambda_fixed_settings,
                                                              position: 40) do |view, _|
          Status.fixed_settings_rows(view)
        end
      end
    end
  end
end
