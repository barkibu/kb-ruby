module KB
  class Error < StandardError
    attr_accessor :status_code, :body, :message

    def initialize(status_code = nil, body = nil, error = nil)
      super(error)
      @status_code = status_code
      @body = body
      @message = "Received Status: #{status_code}\n#{body}"
      set_backtrace error.backtrace if error
    end

    def self.from_faraday(error)
      case error.response[:status]
      when 404
        ResourceNotFound
      when 409
        ConflictError
      when 422
        UnprocessableEntityError
      else
        self
      end.new(error.response[:status], error.response[:body], error)
    end
  end
end
