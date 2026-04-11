# frozen_string_literal: true

require_relative '../mixins/github_body'

module Onebox
  module Engine
    class GithubPullRequestOnebox
      include Engine
      include LayoutSupport
      include JSON
      include Onebox::Mixins::GithubBody

      GITHUB_COMMENT_REGEX = /(<!--.*?-->\r\n)/

      matches_regexp(/^https?:\/\/(?:www\.)?(?:(?:\w)+\.)?(github)\.com(?:\/)?(?:.)*\/pull/)
      always_https

      def url
        "https://api.github.com/repos/#{match[:owner]}/#{match[:repository]}/pulls/#{match[:number]}"
      end

      private

      def match
        @match ||= @url.match(%r{github\.com/(?<owner>[^/]+)/(?<repository>[^/]+)/pull/(?<number>[^/]+)})
      end

      STATUS_DATE_LABELS = {
        "open" => "opened",
        "closed" => "closed",
        "merged" => "merged",
      }.freeze

      PR_STATUS_TITLES = {
        "open" => "Open",
        "closed" => "Closed",
        "merged" => "Merged",
      }.freeze

      def data
        result = raw.clone
        result['link'] = link
        result['pr'] = true

        state = result['merged_at'] ? 'merged' : result['state']
        result['pr_status'] = state
        result['pr_status_title'] = PR_STATUS_TITLES[state] || state

        status_date_str = result['merged_at'] || result['closed_at'] || result['created_at']
        status_date = Time.parse(status_date_str)
        result['status_date'] = status_date.strftime("%I:%M%p - %d %b %y %Z")
        result['status_date_date'] = status_date.strftime("%F")
        result['status_date_time'] = status_date.strftime("%T")

        created_at = Time.parse(result['created_at'])
        result['created_at'] = created_at.strftime("%I:%M%p - %d %b %y %Z")
        result['created_at_date'] = created_at.strftime("%F")
        result['created_at_time'] = created_at.strftime("%T")

        ulink = URI(link)
        result['domain'] = "#{ulink.host}/#{ulink.path.split('/')[1]}/#{ulink.path.split('/')[2]}"

        result['body'], result['excerpt'] = compute_body(result['body'])

        result['i18n'] = {
          'status_date_label' => STATUS_DATE_LABELS[state] || state,
          'pr_summary' => "#{result['changed_files'] || 0} files, +#{result['additions'] || 0}/-#{result['deletions'] || 0}",
        }

        result
      end
    end
  end
end
