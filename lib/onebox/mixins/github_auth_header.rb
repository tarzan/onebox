# frozen_string_literal: true

module Onebox
  module Mixins
    module GithubAuthHeader
      def github_auth_header(github_org)
        tokens = Onebox.options.github_onebox_access_tokens
        return {} if tokens.blank?

        org_tokens = tokens.split("\n").to_h { |entry| entry.split("|") }
        token = org_tokens[github_org] || org_tokens["default"]

        return {} if token.blank?

        { "Authorization" => "Bearer #{token}" }
      end
    end
  end
end
