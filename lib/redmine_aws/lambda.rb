# frozen_string_literal: true

module RedmineAws
  # Running Redmine on AWS Lambda (docs/README.md). The features are on only
  # when REDMINE_ROLE is set (web, worker or task), as on Lambda. What must be
  # in place before Rails initializes is in boot/redmine_aws_lambda.rb.
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
      Admin.register_status_section(:lambda_function, partial: 'aws_lambda/function', position: 10)
      Admin.register_status_section(:lambda_fixed_settings, partial: 'aws_lambda/fixed_settings', position: 40)
    end
  end
end
