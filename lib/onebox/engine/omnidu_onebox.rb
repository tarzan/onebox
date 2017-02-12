module Onebox
  module Engine
    class OmniduOnebox
      include Engine
      include StandardEmbed
      include LayoutSupport

      matches_regexp(/^https?:\/\/.*\.omnidu\.nl\/app\/player/)

      private

      def data
        og = get_opengraph
        result = {
          domain: URI(og[:url]).host,
          url: ::Onebox::Helpers.normalize_url_for_output(og[:url]),
          image: ::Onebox::Helpers.normalize_url_for_output(og[:image]),
          title: og[:title],
          description: og[:description]
        }
      end
    end
  end
end
