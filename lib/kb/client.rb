module KB
  class Client
    # Emitted once per KB call, wrapping cache lookup and the HTTP request.
    # Payload: verb, path, base_url, cache_hit (GET only), status (when a response arrived),
    # plus ActiveSupport's exception/exception_object when the call raised.
    REQUEST_EVENT = 'request.kb_client'.freeze

    attr_reader :api_key, :base_url

    def initialize(base_url, api_key: ENV['KB_API_KEY'])
      @api_key = api_key
      @base_url = base_url
    end

    # `read_timeout` overrides KB.config.request.read_timeout for this one call only,
    # for the few endpoints whose server-side work legitimately runs for seconds
    # (e.g. GET /v1/pets/birthdays). Connect and write budgets stay global.
    def request(sub_path, filters: nil, method: :get, read_timeout: nil)
      return perform(method, sub_path, attributes_to_json(filters), read_timeout: read_timeout) if method != :get

      cache_key = "#{@base_url}/#{sub_path}/#{(filters || {}).sort.to_h}"
      perform(:get, sub_path, filters, cache_key: cache_key, read_timeout: read_timeout)
    end

    def all(filters = {})
      perform(:get, '', attributes_case_transform(filters), cache_key: "#{@base_url}/#{filters.sort.to_h}")
    end

    def find(key, params = {})
      raise Faraday::ResourceNotFound, {} if key.blank?

      perform(:get, key, attributes_case_transform(params), cache_key: "#{@base_url}/#{key}")
    end

    def create(attributes)
      perform(:post, '', attributes_to_json(attributes))
    end

    def update(key, attributes)
      clear_cache_for(key)
      perform(:patch, key.to_s, attributes_to_json(attributes))
    end

    def destroy(key)
      clear_cache_for(key)
      perform(:delete, key.to_s)
    end

    def upsert(attributes)
      perform(:put, '', attributes_to_json(attributes))
    end

    def clear_cache_for(key)
      KB::Cache.delete("#{@base_url}/#{key}")
    end

    private

    # Every public method ends up here, so this is the one place a KB call is
    # observable as a whole: cache lookup, connect, TLS, write, read, parse.
    def perform(verb, path, payload = nil, cache_key: nil, read_timeout: nil)
      event = { verb: verb, path: path, base_url: base_url }
      ActiveSupport::Notifications.instrument(REQUEST_EVENT, event) do
        if cache_key
          event[:cache_hit] = true
          KB::Cache.fetch(cache_key) do
            event[:cache_hit] = false
            http(event, payload, read_timeout)
          end
        else
          http(event, payload, read_timeout)
        end
      end
    end

    def http(event, payload, read_timeout)
      response = connection.public_send(event[:verb], event[:path], payload, &request_options(read_timeout))
      event[:status] = response.status
      response.body
    rescue Faraday::ClientError, Faraday::ServerError => e
      event[:status] = e.response && e.response[:status]
      raise
    end

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
      @connection ||= Faraday.new(url: base_url, headers: headers, request: request_timeouts) do |conn|
        conn.response :json
        conn.response :raise_error
        if KB.config.log_level == :debugger
          conn.response :logger do |logger|
            logger.filter(/(X-api-key:\s)("\w+")/, '\1[API_KEY_SCRUBBED]')
          end
        end
        conn.adapter :net_http
      end
    end

    def request_options(read_timeout)
      return nil if read_timeout.nil?

      ->(req) { req.options.read_timeout = read_timeout }
    end

    def request_timeouts
      {
        open_timeout: KB.config.request.connect_timeout,
        write_timeout: KB.config.request.write_timeout,
        read_timeout: KB.config.request.read_timeout
      }
    end
  end
end
