require 'spec_helper'

RSpec.describe KB::Client do
  let(:client) { described_class.new('http://kb.example/v1/resource') }
  let(:connection) { client.send(:connection) }

  let(:net_http) { transport(Faraday::Adapter::NetHttp) }

  def transport(adapter_class)
    env = Faraday::Env.new
    env.url = URI('http://kb.example/v1/resource')
    env.request = connection.options
    adapter_class.new(nil).build_connection(env)
  end

  it 'uses the keep-alive adapter by default' do
    expect(connection.adapter).to eq Faraday::Adapter::NetHttpPersistent
  end

  it 'uses a plain net_http connection for a call with its own read_timeout' do
    expect(client.send(:connection, 30).adapter).to eq Faraday::Adapter::NetHttp
  end

  it 'shares one connection between clients of the same KB origin' do
    other = described_class.new('http://kb.example/v1/other').send(:connection)

    expect(other).to be connection
  end

  context 'with keep_alive disabled' do
    around do |example|
      KB.config.request.keep_alive = false
      example.run
    ensure
      KB.config.request.keep_alive = true
    end

    it 'falls back to the net_http adapter' do
      expect(connection.adapter).to eq Faraday::Adapter::NetHttp
    end
  end

  it 'sets all three phase timeouts on the Net::HTTP connection' do
    expect(
      open: net_http.open_timeout, write: net_http.write_timeout, read: net_http.read_timeout
    ).to eq(open: 1, write: 3, read: 5)
  end

  it 'keeps Net::HTTP idempotent retries off' do
    expect(net_http.max_retries).to eq 0
  end

  # net-http-persistent defaults to max_retries = 1 and hands it to every pooled
  # Net::HTTP; faraday-net_http's configure_request resets it to 0 per request.
  it 'keeps Net::HTTP idempotent retries off on the pooled transport' do
    expect(transport(Faraday::Adapter::NetHttpPersistent).max_retries).to eq 0
  end

  context 'with configured timeouts' do
    around do |example|
      KB.config.request.connect_timeout = 2
      KB.config.request.write_timeout = 4
      KB.config.request.read_timeout = 12
      example.run
    ensure
      KB.config.request.connect_timeout = 1
      KB.config.request.write_timeout = 3
      KB.config.request.read_timeout = 5
    end

    it 'reads the configured values' do
      expect(
        open: net_http.open_timeout, write: net_http.write_timeout, read: net_http.read_timeout
      ).to eq(open: 2, write: 4, read: 12)
    end
  end
end
