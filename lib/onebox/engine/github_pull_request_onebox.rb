# frozen_string_literal: true

require_relative "../mixins/github_body"
require_relative "../mixins/github_auth_header"

module Onebox
  module Engine
    class GithubPullRequestOnebox
      include Engine
      include LayoutSupport
      include JSON
      include Onebox::Mixins::GithubBody
      include Onebox::Mixins::GithubAuthHeader

      matches_domain("github.com", "www.github.com")
      always_https

      def self.matches_path(path)
        path.match?(%r{.*/pull})
      end

      def url
        "https://api.github.com/repos/#{match[:org]}/#{match[:repository]}/pulls/#{match[:number]}"
      end

      private

      def match
        @match ||=
          @url.match(%r{github\.com/(?<org>[^/]+)/(?<repository>[^/]+)/pull/(?<number>[^/]+)})
      end

      def data
        result = raw(github_auth_header(match[:org])).clone
        result["link"] = link

        status_data = fetch_pr_status(result)
        result["pr_status"] = status_data&.dig(:status)
        result["pr_status_title"] = pr_status_title(result["pr_status"])

        status_timestamp = status_data&.dig(:timestamp) || result["created_at"]
        status_date = Time.parse(status_timestamp)
        result["status_date"] = status_date.strftime("%I:%M%p - %d %b %y %Z")
        result["status_date_date"] = status_date.strftime("%F")
        result["status_date_time"] = status_date.strftime("%T")

        ulink = URI(link)
        _, org, repo = ulink.path.split("/")
        result["domain"] = "#{ulink.host}/#{org}/#{repo}"

        result["body"], result["excerpt"] = compute_body(result["body"])

        if result["commit"] = load_commit(link)
          result["body"], result["excerpt"] =
            compute_body(result["commit"]["commit"]["message"].lines[1..].join)
        elsif result["comment"] = load_comment(link)
          result["body"], result["excerpt"] = compute_body(result["comment"]["body"])
        elsif result["discussion"] = load_review(link)
          result["body"], result["excerpt"] = compute_body(result["discussion"]["body"])
        else
          result["pr"] = true
        end

        result["number"] = match[:number]
        result["i18n"] = i18n
        result["i18n"]["status_date_label"] = status_date_label(result["pr_status"])
        result["i18n"]["pr_summary"] = "#{result["commits"]} commits changed #{result["changed_files"]} files with #{result["additions"]} additions and #{result["deletions"]} deletions"
        result["is_private"] = result.dig("base", "repo", "private")

        result["base"]["label"].sub!(/\A#{org}:/, "")
        result["head"]["label"].sub!(/\A#{org}:/, "")

        result
      end

      STATUS_DATE_LABELS = {
        "open" => "opened",
        "merged" => "merged",
        "closed" => "closed",
        "draft" => "opened as draft",
        "approved" => "approved",
        "changes_requested" => "changes requested",
      }.freeze

      PR_STATUS_TITLES = {
        "default" => "Pull Request",
        "open" => "Open Pull Request",
        "merged" => "Merged Pull Request",
        "closed" => "Closed Pull Request",
        "draft" => "Draft Pull Request",
        "approved" => "Approved Pull Request",
        "changes_requested" => "Changes Requested",
      }.freeze

      def i18n
        {
          opened: "opened",
          commit_by: "committed",
          comment_by: "commented",
          review_by: "reviewed",
        }
      end

      def status_date_label(status)
        key = status.presence || "open"
        STATUS_DATE_LABELS[key] || key
      end

      def pr_status_title(status)
        key = status.presence || "default"
        PR_STATUS_TITLES[key] || "Pull Request"
      end

      def load_commit(link)
        if commit_match = link.match(%r{commits/(\h+)})
          load_json(
            "https://api.github.com/repos/#{match[:org]}/#{match[:repository]}/commits/#{commit_match[1]}",
          )
        end
      end

      def load_comment(link)
        if comment_match = link.match(/#issuecomment-(\d+)/)
          load_json(
            "https://api.github.com/repos/#{match[:org]}/#{match[:repository]}/issues/comments/#{comment_match[1]}",
          )
        end
      end

      def load_review(link)
        if review_match = link.match(/#discussion_r(\d+)/)
          load_json(
            "https://api.github.com/repos/#{match[:org]}/#{match[:repository]}/pulls/comments/#{review_match[1]}",
          )
        end
      end

      def load_json(url)
        ::MultiJson.load(
          URI.parse(url).open({ read_timeout: timeout }.merge(github_auth_header(match[:org]))),
        )
      rescue OpenURI::HTTPError => e
        warn("GitHub API error: #{e.io.status[0]} fetching #{url}")
        raise
      end

      def fetch_pr_status(pr_data)
        return { status: "merged", timestamp: pr_data["merged_at"] } if pr_data["merged"]
        return { status: "closed", timestamp: pr_data["closed_at"] } if pr_data["state"] == "closed"
        return { status: "draft", timestamp: pr_data["created_at"] } if pr_data["draft"]

        reviews_data = load_json(url + "/reviews")
        latest_reviews = latest_review_states_with_timestamps(reviews_data)

        %w[CHANGES_REQUESTED APPROVED].each do |state|
          reviews = latest_reviews.select { |r| r[:state] == state }
          if reviews.present?
            return { status: state.downcase, timestamp: reviews.map { |r| r[:timestamp] }.max }
          end
        end

        { status: "open", timestamp: pr_data["created_at"] }
      rescue StandardError => e
        warn("GitHub PR status fetch error: #{e.message}")
        nil
      end

      def latest_review_states_with_timestamps(reviews)
        return [] if reviews.blank?

        reviews
          .reject do |r|
            r.dig("user", "id").nil? || !%w[CHANGES_REQUESTED APPROVED].include?(r["state"])
          end
          .group_by { |r| r.dig("user", "id") }
          .transform_values { |rs| rs.max_by { |r| r["submitted_at"] } }
          .values
          .map { |r| { state: r["state"], timestamp: r["submitted_at"] } }
      end
    end
  end
end
