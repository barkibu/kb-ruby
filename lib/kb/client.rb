module KB
  class Client
    attr_reader :api_key, :base_url

    def initialize(base_url, api_key: ENV['KB_API_KEY'])
      @api_key = api_key
      @base_url = base_url
    end

    def request(sub_path, filters: {}, method: :get)
      connection.public_send(method, sub_path, filters).body
    end

    def all(filters = {})
      connection.get('', attributes_case_transform(filters)).body
    end

    def find(key)
      raise Faraday::ResourceNotFound, {} if key.blank?

      connection.get(key).body
    end

    def create(attributes)
      connection.post('', attributes_to_json(attributes)).body
    end

    def update(key, attributes)
      connection.patch(key.to_s, attributes_to_json(attributes)).body
    end

    private

    def headers
      {
        'Content-Type': 'application/json',
        'x-api-key': api_key
      }
    end

    def attributes_case_transform(attributes)
      attributes.transform_keys do |key|
        key.to_s.camelize(:lower)
      end
    end

    def attributes_to_json(attributes)
      attributes_case_transform(attributes).to_json
    end

    def connection
      @connection ||= Faraday.new(url: base_url, headers: headers) do |conn|
        conn.params['locale'] = I18n.locale
        conn.response :json
        conn.response :raise_error
        conn.response :logger do |logger|
          logger.filter(/(X-api-key:\s)("\w+")/, '\1[API_KEY_SCRUBBED]')
        end
        conn.adapter :http
      end
    end
  end
end
