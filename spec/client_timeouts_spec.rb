require 'spec_helper'

RSpec.describe KB::Client do
  let(:connection) { described_class.new('http://kb.example/v1/resource').send(:connection) }

  let(:net_http) do
    env = Faraday::Env.new
    env.url = URI('http://kb.example/v1/resource')
    env.request = connection.options
    Faraday::Adapter::NetHttp.new(nil).build_connection(env)
  end

  it 'uses the net_http adapter' do
    expect(connection.adapter).to eq Faraday::Adapter::NetHttp
  end

  it 'sets all three phase timeouts on the Net::HTTP connection' do
    expect(
      open: net_http.open_timeout, write: net_http.write_timeout, read: net_http.read_timeout
    ).to eq(open: 1, write: 3, read: 5)
  end

  it 'keeps Net::HTTP idempotent retries off' do
    expect(net_http.max_retries).to eq 0
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
