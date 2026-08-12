require 'spec_helper'
require 'barkibu-kb-fake'

RSpec.describe KB::Fake::Api do
  # Sinatra >= 4.1 authorizes the Host header (dev-inferred environments only
  # permit localhost-style hosts), and with the net_http adapter WebMock
  # intercepts before Net::HTTP adds the Host header at all. The fake must
  # accept both request shapes without any consumer-side configuration.
  it 'accepts requests addressed to the stubbed KB host' do
    env = Rack::MockRequest.env_for('http://test_api_barkkb.com/v1/breeds')
    env['HTTP_HOST'] = 'test_api_barkkb.com'

    status, = described_class.call(env)

    expect(status).to eq 200
  end

  it 'accepts requests that carry no Host header' do
    env = Rack::MockRequest.env_for('http://test_api_barkkb.com/v1/breeds')

    status, = described_class.call(env)

    expect(status).to eq 200
  end
end
