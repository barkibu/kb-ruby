module KB
  class Error < StandardError
    attr_accessor :status_code, :body

    def initialize(status_code = nil, body = nil, error = nil)
      super(error)
      @status_code = status_code
      @body = body
      set_backtrace error.backtrace if error
    end

    def message
      error_msg = "Received Status: #{status_code}\n"
      error_msg << body.to_s
      error_msg
    end
  end

  class ResourceNotFound < Error; end
end
