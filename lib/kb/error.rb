module KB
  class Error < StandardError
    attr_accessor :status_code, :body

    def initialize(status_code, body, error)
      super(error)
      @status_code = status_code
      @body = body
      set_backtrace error.backtrace if error
    end
  end

  class ResourceNotFound < Error; end
end
