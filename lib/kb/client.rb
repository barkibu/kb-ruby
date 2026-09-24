module KB
  class Client
    # Emitted once per KB call, wrapping cache lookup and the HTTP request.
    # Payload: verb, path, base_url, cache_hit (GET only), status (when a response arrived),
    # retries / retry_errors (only when the call was retried, see KB::RetryPolicy),
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
      response = send_request(event, payload, read_timeout)
      event[:status] = response.status
      response.body
    rescue Faraday::ClientError, Faraday::ServerError => e
      event[:status] = e.response && e.response[:status]
      raise
    end

    def send_request(event, payload, read_timeout)
      connection(read_timeout).public_send(event[:verb], url_for(event[:path]), payload) do |req|
        req.headers[:'x-api-key'] = api_key # a symbol, so Faraday names it X-api-key, as the log filter expects
        req.options.read_timeout = read_timeout if read_timeout
        RetryPolicy.track(req, event, read_timeout)
      end
    end

    def attributes_case_transform(attributes)
      attributes.transform_keys do |key|
        key.to_s.camelize(:lower)
      end
    end

    def attributes_to_json(attributes)
      attributes_case_transform(attributes).to_json
    end

    # The process-wide connection every client shares (see KB::Connections):
    # keep-alive unless disabled, or unless this one call sets its own read_timeout.
    def connection(read_timeout = nil)
      Connections.fetch(keep_alive: KB.config.request.keep_alive && read_timeout.nil?)
    end

    # The URL a Faraday connection on base_url would build for `path`, by Faraday's
    # own joining rules ("" is base_url itself, anything else is relative to
    # base_url + "/"), so sharing one connection across clients changes no URL.
    def url_for(path)
      @url_builder ||= Faraday::Connection.new(url: base_url)
      @url_builder.build_exclusive_url(path).to_s
    end
  end
end
