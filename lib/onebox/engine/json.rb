# frozen_string_literal: true

module Onebox
  module Engine
    module JSON
      private

      def raw(http_headers = {})
        @raw ||= ::MultiJson.load(URI.open(url, { read_timeout: timeout }.merge(http_headers)))
      end
    end
  end
end
