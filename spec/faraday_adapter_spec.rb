require 'spec_helper'

RSpec.describe KB::FaradayAdapter do
  subject(:http_client) do
    described_class.new(nil).send(:setup_connection, env)
  end

  let(:env) do
    Faraday::Env.new.tap do |e|
      e.request = Faraday::RequestOptions.new
      e.request_headers = {}
    end
  end

  it 'uses per-operation timeouts' do
    expect(http_client.default_options.timeout_class).to eq HTTP::Timeout::PerOperation
  end

  it 'sets all three phase timeouts explicitly, never falling back to http.rb defaults' do
    expect(http_client.default_options.timeout_options).to eq(
      connect_timeout: 1,
      write_timeout: 3,
      read_timeout: 5
    )
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
      expect(http_client.default_options.timeout_options).to eq(
        connect_timeout: 2,
        write_timeout: 4,
        read_timeout: 12
      )
    end
  end
end
