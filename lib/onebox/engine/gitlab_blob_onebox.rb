# frozen_string_literal: true

require_relative "../mixins/git_blob_onebox"

module Onebox
  module Engine
    class GitlabBlobOnebox
      def self.git_regexp
        %r{^https?://(?:www\.)?gitlab\.com/.*/blob/.*}
      end

      def self.onebox_name
        "gitlabblob"
      end

      include Onebox::Mixins::GitBlobOnebox

      def i18n
        {
          truncated_file: "This file has been truncated.",
          show_original: "Show original",
        }
      end

      def raw_regexp
        %r{gitlab\.com/(?<user>[^/]+)/(?<repo>[^/]+)/blob/(?<sha1>[^/]+)/(?<file>[^#]+)(#(L(?<from>[^-]*)(-L(?<to>.*))?))?}mi
      end

      def raw_template(m)
        "https://gitlab.com/#{m[:user]}/#{m[:repo]}/raw/#{m[:sha1]}/#{m[:file]}"
      end

      def auth_headers(_match)
        {}
      end

      private

      def data
        super.merge({ domain: "gitlab.com/#{match[:user]}/#{match[:repo]}" })
      end
    end
  end
end
