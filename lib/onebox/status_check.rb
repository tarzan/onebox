# frozen_string_literal: true

module Onebox
  class StatusCheck
    def initialize(url, options = Onebox.options)
      @url = url
      @options = options
      @status = -1
    end

    def ok?
      status > 199 && status < 300
    end

    def status
      check if @status == -1
      @status
    end

    def human_status
      case status
      when 0
        :connection_error
      when 200..299
        :success
      when 400..499
        :client_error
      when 500..599
        :server_error
      else
        :unknown_error
      end
    end

    private

    def check
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = @options.timeout || Onebox.options.timeout
      http.read_timeout = @options.timeout || Onebox.options.timeout
      response = http.request_get(uri.request_uri)
      @status = response.code.to_i
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::HTTPError
      @status = 0
    end
  end
end
