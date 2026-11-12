# frozen_string_literal: true

require_relative '../test_helper'

module RedmineAws
  module Lambda
    class EventsMiddlewareTest < Redmine::IntegrationTest
      include Lambda::TestHelper

      def test_events_returns_204_without_touching_the_database
        queries = with_role('web') do
          sql_queries do
            post '/events', params: '{"source":"aws.events"}', headers: { 'CONTENT_TYPE' => 'application/json' }
          end
        end

        assert_response 204
        assert_empty response.body
        assert_empty queries
        assert_nil response.headers['Set-Cookie']
      end

      # /events can also be reached through CloudFront by any viewer: every
      # method gets the same empty 204, whatever the Host.
      def test_events_answers_every_method_and_host_the_same
        %i[get post put patch delete].each do |method|
          with_role('web') do
            process method, '/events', params: 'x' * 1024, headers: { 'HTTP_HOST' => 'evil.example.net' }
          end

          assert_response 204, method
          assert_empty response.body, method
          assert_nil response.headers['Set-Cookie'], method
        end
      end

      def test_other_paths_pass_through
        with_role('web') do
          get '/login'
        end

        assert_response :success
        %w[/events/ /events.json /events/1].each do |path|
          with_role('web') { get path }

          assert_response :not_found, path
        end
      end

      def test_events_is_not_handled_without_the_role
        with_role(nil) do
          post '/events'
        end

        assert_response :not_found
      end

      def test_the_middleware_is_first
        assert_equal Boot::EventsMiddleware, Rails.application.middleware.first.klass
      end

      private

      # The SQL statements that ActiveRecord ran in the block.
      def sql_queries(&)
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
        queries
      end
    end
  end
end
