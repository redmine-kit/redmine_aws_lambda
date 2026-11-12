# frozen_string_literal: true

module RedmineAws
  module Lambda
    # What this plugin adds to the Status tab of redmine_aws
    # (docs/admin.md#status). No secret values: only names.
    module Status
      def self.function
        {
          name: ENV.fetch('AWS_LAMBDA_FUNCTION_NAME', nil),
          role: Lambda.role,
          version: ENV.fetch('AWS_LAMBDA_FUNCTION_VERSION', nil),
          memory: ENV.fetch('AWS_LAMBDA_FUNCTION_MEMORY_SIZE', nil),
          region: ENV.fetch('AWS_REGION', nil),
          image: ENV.fetch('REDMINE_IMAGE', nil)
        }
      end

      def self.fixed_settings
        Settings::FIXED.keys.map { |name| [name, Setting.public_send(name)] }
      end
    end
  end
end
