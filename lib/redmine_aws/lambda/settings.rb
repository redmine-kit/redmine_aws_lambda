# frozen_string_literal: true

module RedmineAws
  module Lambda
    # Redmine settings that cannot work on Lambda, fixed while REDMINE_ROLE is
    # set (docs/admin.md#redmine-settings-that-cannot-work-on-lambda). Redmine
    # generates these readers on Setting (Setting.define_setting); they are the
    # only Redmine code the plugin replaces. Values saved from the settings page
    # stay in the database and are not used.
    module Settings
      FIXED = {
        autofetch_changesets: '0',
        sys_api_enabled: '0',
        mail_handler_api_enabled: '0'
      }.freeze

      # The repository types whose clients the image has. The others stay off
      # whatever is saved, and on Lambda they are removed from Redmine's list
      # of repository types, so that the settings page and the repository
      # form don't offer them.
      SCM = %w[Subversion Git].freeze

      # Setting.<name> and Setting.<name>?, which Setting.define_setting
      # writes; super is Redmine's reader, used without the role.
      FIXED.each do |name, value|
        define_method(name) { Lambda.lambda? ? value.dup : super() }
        define_method(:"#{name}?") { Lambda.lambda? ? false : super() }
      end

      # Setting.enabled_scm, which Repository#repo_create_validation and the
      # repository form (RepositoriesHelper#scm_select_tag) read.
      def enabled_scm
        Lambda.lambda? ? super & SCM : super
      end

      # Called from setup, on every code reload: after Redmine's own
      # preparation, which adds the repository types again.
      def self.install
        Setting.singleton_class.prepend(self) unless Setting.singleton_class.include?(self)
        SettingsController.helper(SettingsHelper)
        return unless Lambda.lambda?

        # Redmine::Scm::Base.delete: Redmine's way to remove a repository type.
        (Redmine::Scm::Base.all - SCM).each { |name| Redmine::Scm::Base.delete(name) }
      end
    end
  end
end
