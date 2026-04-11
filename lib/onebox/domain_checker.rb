# frozen_string_literal: true

module Onebox
  class DomainChecker
    def self.is_blocked?(hostname)
      blocked_domains = Onebox.options.blocked_onebox_domains
      return false if blocked_domains.blank?

      blocked_domains
        .split("|")
        .any? { |blocked| hostname == blocked || hostname.end_with?(".#{blocked}") }
    end
  end
end
