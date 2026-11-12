# frozen_string_literal: true

require_relative '../test_helper'

module RedmineAws
  module Lambda
    # Redmine's settings page on Lambda: the settings fixed by Settings are
    # disabled with a note (SettingsHelper), and only the repository types of
    # Settings::SCM are listed. Every tab is rendered with the page.
    class SettingsPageTest < Redmine::ControllerTest
      include Lambda::TestHelper

      tests SettingsController

      NOTE = "Can't be set in this environment"

      def setup
        @request.session[:user_id] = 1
        Settings::FIXED.each_key { |name| Setting.public_send(:"#{name}=", '1') }
        Setting.commit_logs_formatting = '1'
      end

      def scm_names
        css_select('fieldset.enabled_scm td.scm_name label').map { |label| label.text.strip }
      end

      def test_the_fixed_settings_are_disabled_with_a_note_on_lambda
        on_lambda { get :edit, params: { tab: 'repositories' } }

        assert_response :success
        Settings::FIXED.each_key do |name|
          assert_select "p input#settings_#{name}[type=checkbox][disabled]:not([checked]) ~ em.info", { text: NOTE },
                        name
          assert_select "p input[type=hidden][name='settings[#{name}]'][value='0']", 1, name
        end
      end

      def test_the_other_settings_stay_as_redmine_shows_them_on_lambda
        on_lambda { get :edit, params: { tab: 'repositories' } }

        assert_select 'input#settings_commit_logs_formatting[checked]:not([disabled])'
        assert_select 'input#settings_commit_logs_formatting ~ em.info', 0
      end

      def test_only_subversion_and_git_are_listed_on_lambda
        on_lambda { get :edit, params: { tab: 'repositories' } }

        assert_equal Settings::SCM, scm_names
      end

      def test_standard_page_without_the_role
        with_role(nil) { get :edit, params: { tab: 'repositories' } }

        assert_response :success
        assert_not_includes response.body, NOTE
        Settings::FIXED.each_key do |name|
          assert_select "input#settings_#{name}[type=checkbox][checked]:not([disabled])", 1, name
        end
        assert_equal Redmine::Scm::Base.all, scm_names
        assert_operator scm_names.size, :>, Settings::SCM.size
      end
    end
  end
end
