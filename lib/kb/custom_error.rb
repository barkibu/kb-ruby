module KB
  class CustomError < Error
    def initialize(error)
      super(nil, error, nil)
      @message = error
    end

    attr_reader :message
  end
end
