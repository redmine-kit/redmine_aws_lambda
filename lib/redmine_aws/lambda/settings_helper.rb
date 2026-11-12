# frozen_string_literal: true

module RedmineAws
  module Lambda
    # On Lambda, Redmine's settings page shows the settings that Settings fixes
    # as disabled checkboxes with a note. Added to SettingsController with
    # SettingsController.helper (Settings.install); overrides
    # SettingsHelper#setting_check_box, which renders the checkbox of a
    # setting, because the Repositories and Incoming emails tabs have no hook
    # inside their forms.
    # The checkbox is unchecked already: it shows the value of Setting's reader.
    module SettingsHelper
      def setting_check_box(setting, options = {})
        return super unless Lambda.lambda? && Settings::FIXED.key?(setting.to_sym)

        safe_join([super(setting, options.merge(disabled: true)),
                   tag.em(l(:text_aws_lambda_setting_fixed), class: 'info')])
      end
    end
  end
end
