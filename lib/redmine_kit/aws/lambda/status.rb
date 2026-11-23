# frozen_string_literal: true

module RedmineKit
  module Aws
    module Lambda
      # What this plugin adds to the Status tab of redmine_kit_aws
      # (docs/admin.md#status). No secret values: only names.
      module Status
        def self.function
          {
            name: ENV.fetch('AWS_LAMBDA_FUNCTION_NAME', nil),
            role: Lambda.role,
            version: ENV.fetch('AWS_LAMBDA_FUNCTION_VERSION', nil),
            memory: ENV.fetch('AWS_LAMBDA_FUNCTION_MEMORY_SIZE', nil),
            region: ENV.fetch('AWS_REGION', nil),
            image: ENV.fetch('REDMINE_LAMBDA_IMAGE', nil)
          }
        end

        def self.fixed_settings
          Settings::FIXED.keys.map { |name| [name, Setting.public_send(name)] }
        end

        # The section Lambda function: its rows, formatted with the view's
        # helpers, for Redmine's page and the new UI's JSON alike
        # (RedmineKit::Aws::Admin.register_status_section). "-" for a value
        # that is not set, as Redmine shows a blank field.
        def self.function_rows(view)
          function = self.function
          memory = function[:memory] && "#{view.number_with_delimiter(function[:memory].to_i)} MB"
          values = function.merge(memory: memory)
          %i[name role version memory region image].map do |key|
            row = { name: view.l(:"field_aws_lambda_function_#{key}"), value: values[key] || '-' }
            key == :role ? row.merge(note: 'REDMINE_ROLE') : row
          end
        end

        # The section Read-only settings: each setting this plugin fixes, its
        # value as Redmine shows a yes/no and its name; none off Lambda
        # ("No data to display").
        def self.fixed_settings_rows(view)
          return [] unless Lambda.lambda?

          fixed_settings.map do |name, value|
            { name: view.l(:"setting_#{name}"), value: view.format_object(value.to_s == '1'), note: name.to_s }
          end
        end
      end
    end
  end
end
