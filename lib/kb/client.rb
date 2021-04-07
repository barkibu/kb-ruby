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
      cache_key = "#{@base_url}/#{filters.sort.to_h}"

      KB.config.cache.instance.fetch(cache_key, expires_in: KB.config.cache.expires_in.to_f) do
        connection.get('', attributes_case_transform(filters)).body
      end
    end

    def find(key, params = {})
      raise Faraday::ResourceNotFound, {} if key.blank?

      KB.config.cache.instance.fetch("#{@base_url}/#{key}", expires_in: KB.config.cache.expires_in.to_f) do
        connection.get(key, attributes_case_transform(params)).body
      end
    end

    def create(attributes)
      connection.post('', attributes_to_json(attributes)).body
    end

    def update(key, attributes)
      KB.config.cache.instance.delete("#{@base_url}/#{key}")
      connection.patch(key.to_s, attributes_to_json(attributes)).body
    end

    def destroy(key)
      KB.config.cache.instance.delete("#{@base_url}/#{key}")
      connection.delete(key.to_s).body
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
        conn.response :json
        conn.response :raise_error
        if KB.config.log_level == :debugger
          conn.response :logger do |logger|
            logger.filter(/(X-api-key:\s)("\w+")/, '\1[API_KEY_SCRUBBED]')
          end
        end
        conn.adapter :http
      end
    end
  end
end
