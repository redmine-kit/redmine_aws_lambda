# frozen_string_literal: true

# Redmine Kit AWS Lambda as a gem (docs/setup.md#installation): Bundler requires this file
# when Redmine's Gemfile.local has `gem 'redmine_kit_aws_lambda'`, or (with a checkout in
# plugins/) the plugin's Gemfile names it by path.
#
# Redmine 7.0.3 loads plugins from its plugins/ folder only
# (Redmine::PluginLoader). This hands the gem's folder to the same loader,
# after Redmine's initializers have listed plugins/: Redmine then runs
# init.rb (which registers the plugin with this folder, `directory`) and
# serves its assets, locales, views and migrations as for any plugin; the
# folder's lib/ and app/ go to Rails' code loader (Zeitwerk) as Redmine adds a
# plugin's (PluginLoader.add_autoload_paths); its routes come after Redmine's,
# as Redmine draws a plugin's. A plugin of the same id in plugins/ (a checkout
# or a link) wins, and nothing is done (redmine_kit_ui's template,
# examples/redmine_kit_example).
#
# The part of Redmine Kit AWS Lambda that must be in place before Rails finishes
# initializing: the /events and forwarded host middlewares and the asset
# setting. Bundler loads this file (the plugin is also a gem); init.rb, which
# Redmine runs later, does the rest. It is outside lib/, which Redmine
# autoloads. It defines only RedmineKit::Aws::Lambda::Boot: the modules around
# it are empty and nested here (RedmineKit belongs to no plugin), and
# lib/redmine_kit/aws.rb and lib/redmine_kit/aws/lambda.rb, which the code
# loader then skips, are loaded by the init.rb files.

require 'active_support/lazy_load_hooks'
# The gems of the plugins it requires (config/dependencies.yml): Bundler
# installs them with this one, and their boot files hand their folders to
# Redmine's plugin loader too.
require 'yaml'
YAML.safe_load_file(File.expand_path('../config/dependencies.yml', __dir__))['requires'].each_key do |name|
  require name
end

ActiveSupport.on_load(:before_configuration, yield: true) do |app|
  dir = File.expand_path('..', __dir__)
  app.initializer 'redmine_kit_aws_lambda.gem', after: :load_config_initializers do |application|
    loader = Redmine::PluginLoader
    next if loader.directories.any? { |path| File.basename(path.to_s) == 'redmine_kit_aws_lambda' }

    loader.directories << Redmine::PluginPath.new(dir)
    Rails::Engine::Configuration.new(dir).tap { |config| config.paths.add 'lib', eager_load: true }
                                .all_eager_load_paths.each do |path|
      Rails.autoloaders.main.push_dir(path)
      application.config.watchable_dirs[path] = [:rb]
    end
    routes = File.join(dir, 'config/routes.rb')
    application.routes.append { instance_eval(File.read(routes), routes) } if File.file?(routes)
  end
end

module RedmineKit
  module Aws
    module Lambda
      module Boot
        # Answers Lambda Web Adapter's /events with 204 before anything else runs,
        # so that it never touches the database or a session. Other paths, and
        # every path when REDMINE_ROLE is not set, pass through.
        class EventsMiddleware
          PATH = '/events'

          def initialize(app)
            @app = app
          end

          def call(env)
            return @app.call(env) unless ENV.fetch('REDMINE_ROLE', '') != '' && env['PATH_INFO'] == PATH

            [204, {}, []]
          end
        end

        # Makes the Redmine domain the Host of requests on Lambda. They come through
        # CloudFront and the function URL, whose own host name is the Host (the
        # function URL and origin access control need it), and CloudFront passes the
        # domain in X-Forwarded-Host, an origin custom header that replaces one sent
        # by the viewer. Rails' host authorization checks both Host and
        # X-Forwarded-Host against config.hosts, which holds only the domain; with the
        # domain in Host, Rails checks and builds URLs with the domain alone. Without
        # X-Forwarded-Host the function URL's host stays and the request is blocked.
        # Every request passes unchanged when REDMINE_ROLE is not set.
        class ForwardedHostMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            if ENV.fetch('REDMINE_ROLE', '') != ''
              host = env['HTTP_X_FORWARDED_HOST'].to_s.split(/,\s?/).last
              env['HTTP_HOST'] = host if host.present?
            end
            @app.call(env)
          end
        end

        if defined?(Rails::Railtie)
          class Railtie < Rails::Railtie
            config.app_middleware.insert_before 0, EventsMiddleware
            # Before Rails' host authorization, which is the first middleware of the
            # stack when config.hosts is not empty.
            config.app_middleware.insert_after EventsMiddleware, ForwardedHostMiddleware

            # Redmine checks after initialization whether the assets changed and
            # writes them to public/assets; on Lambda the image has them compiled
            # and the file system is read-only. This runs before Redmine's check,
            # which is registered later.
            config.after_initialize do |app|
              app.config.assets.redmine_detect_update = false if ENV.fetch('REDMINE_ROLE', '') != ''
            end
          end
        end
      end
    end
  end
end
