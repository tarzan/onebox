# frozen_string_literal: true

module Onebox
  module Mixins
    module RedditAuthHeader
      def reddit_auth_header
        client_id = Onebox.options.reddit_onebox_client_id
        client_secret = Onebox.options.reddit_onebox_client_secret
        if client_id.blank? || client_secret.blank?
          return {}
        end

        token = fetch_reddit_access_token
        return {} if token.blank?

        { "Authorization" => "Bearer #{token}" }
      end

      def reddit_authenticated?
        Onebox.options.reddit_onebox_client_id.present? &&
          Onebox.options.reddit_onebox_client_secret.present?
      end

      private

      def fetch_reddit_access_token
        @reddit_access_token ||=
          begin
            user = Onebox.options.reddit_onebox_client_id
            password = Onebox.options.reddit_onebox_client_secret

            uri = URI("https://www.reddit.com/api/v1/access_token")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Post.new(uri)
            request.basic_auth(user, password)
            request.set_form_data(grant_type: "client_credentials")
            request["User-Agent"] = Onebox::Helpers.user_agent
            request["Content-Type"] = "application/x-www-form-urlencoded"

            response = http.request(request)

            ::MultiJson.load(response.body)["access_token"] if response.code.to_i == 200
          end
      end
    end
  end
end
