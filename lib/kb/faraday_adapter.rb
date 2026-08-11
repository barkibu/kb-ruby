module KB
  # faraday-http's request_config can only express http.rb's global timeout
  # (`timeout`) or connect+write (`open_timeout`) — and setting `open_timeout`
  # switches http.rb to per-operation mode where an unset read timeout silently
  # becomes 0.25s. Overriding request_config is the only seam that can set all
  # three phases explicitly.
  class FaradayAdapter < Faraday::Adapter::HTTP
    private

    def request_config(conn, _config)
      conn.timeout(
        connect: KB.config.request.connect_timeout,
        write: KB.config.request.write_timeout,
        read: KB.config.request.read_timeout
      )
    end
  end
end
