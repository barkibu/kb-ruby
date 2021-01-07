module KB
  class Error
    attr_accessor :status_code, :body

    def initialize(status_code, body)
      @status_code = status_code
      @body = body
    end
  end
end
