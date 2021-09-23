module KB
  class ClientError < Error
    def message
      JSON.parse(body)['message']
    rescue StandardError
      body
    end
  end
end
