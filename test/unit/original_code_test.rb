# frozen_string_literal: true

require_relative '../test_helper'
require 'digest'

module RedmineAws
  module Lambda
    # The plugin replaces the readers that Setting.define_setting writes
    # (Lambda::Settings) and wraps SettingsHelper#setting_check_box
    # (Lambda::SettingsHelper). If an upgrade of Redmine changes one of these
    # methods, this test fails, so that the replacement is reviewed.
    class OriginalCodeTest < ActiveSupport::TestCase
      DEFINE_SETTING = '0384523872c1238e3a0c8f3f2911d75af5b0c50416c22d80456b51d9c80d1569'
      SETTING_CHECK_BOX = '8efd247c697ee7b0ec8feb5b6c3bb3a76065d492192b06f444f94043a37af5bf'

      def method_source(method)
        file, line = method.source_location
        lines = File.readlines(file)[(line - 1)..]
        indent = lines.first[/\A */]
        last = lines.index { |l| l == "#{indent}end\n" }
        lines[0..last].join
      end

      def test_setting_define_setting_is_unchanged
        assert_equal DEFINE_SETTING, Digest::SHA256.hexdigest(method_source(Setting.method(:define_setting)))
      end

      def test_settings_helper_setting_check_box_is_unchanged
        method = ::SettingsHelper.instance_method(:setting_check_box)

        assert_equal SETTING_CHECK_BOX, Digest::SHA256.hexdigest(method_source(method))
      end
    end
  end
end
