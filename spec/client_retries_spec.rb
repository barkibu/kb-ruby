require 'spec_helper'

RSpec.describe KB::Client, '#request retries' do
  subject(:client) { described_class.new('http://kb.test/v1/pets', api_key: 'test') }

  let(:json) { { status: 200, body: '{"key":"k"}', headers: { 'Content-Type' => 'application/json' } } }
  let(:events) { [] }

  around do |example|
    KB.config.request.retry_interval = 0
    subscriber = ActiveSupport::Notifications.subscribe(described_class::REQUEST_EVENT) { |*, p| events << p }
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
    KB.config.request.retry_interval = 0.1
    KB.config.request.retries = 1
  end

  # Runs the call and returns what the caller saw plus how many HTTP attempts reached the stub.
  def call(stub)
    result = begin
      yield
      :ok
    rescue Faraday::Error => e
      e.class
    end
    { result: result, attempts: WebMock::RequestRegistry.instance.times_executed(stub.request_pattern) }
  end

  it 'retries a GET after a connect timeout and reports the retry in the event' do
    stub = stub_request(:get, 'http://kb.test/v1/pets/k').to_raise(Net::OpenTimeout).then.to_return(json)

    outcome = call(stub) { client.find('k') }

    expect(outcome.merge(event: events.last.slice(:status, :retries, :retry_errors)))
      .to eq(result: :ok, attempts: 2, event: { status: 200, retries: 1, retry_errors: ['Net::OpenTimeout'] })
  end

  it 'retries a POST when the request never reached KB' do
    stub = stub_request(:post, 'http://kb.test/v1/pets').to_raise(Errno::ECONNREFUSED).then.to_return(json)

    expect(call(stub) { client.create(name: 'Rex') }).to eq(result: :ok, attempts: 2)
  end

  it 'does not retry a POST that may have reached KB' do
    stub = stub_request(:post, 'http://kb.test/v1/pets').to_raise(Net::ReadTimeout).then.to_return(json)

    expect(call(stub) { client.create(name: 'Rex') }).to eq(result: Faraday::TimeoutError, attempts: 1)
  end

  it 'retries a GET after a read timeout' do
    stub = stub_request(:get, 'http://kb.test/v1/pets/k').to_raise(Net::ReadTimeout).then.to_return(json)

    expect(call(stub) { client.find('k') }).to eq(result: :ok, attempts: 2)
  end

  it 'does not retry a read timeout on a call that set its own read_timeout' do
    stub = stub_request(:get, 'http://kb.test/v1/pets/birthdays').to_raise(Net::ReadTimeout).then.to_return(json)

    expect(call(stub) { client.request('birthdays', read_timeout: 30) })
      .to eq(result: Faraday::TimeoutError, attempts: 1)
  end

  it 'does not retry HTTP error responses' do
    stub = stub_request(:get, 'http://kb.test/v1/pets/k').to_return(status: 503, body: '')

    expect(call(stub) { client.find('k') }).to eq(result: Faraday::ServerError, attempts: 1)
  end

  it 'gives up after the configured retries and records the last error on the event' do
    stub = stub_request(:get, 'http://kb.test/v1/pets/k').to_raise(Net::OpenTimeout)

    outcome = call(stub) { client.find('k') }

    expect(outcome.merge(retries: events.last[:retries], recorded: events.last[:exception_object].class))
      .to eq(result: Faraday::TimeoutError, attempts: 2, retries: 1, recorded: Faraday::TimeoutError)
  end

  it 'does not retry when retries are set to 0' do
    KB.config.request.retries = 0
    stub = stub_request(:get, 'http://kb.test/v1/pets/k').to_raise(Net::OpenTimeout).then.to_return(json)

    expect(call(stub) { client.find('k') }).to eq(result: Faraday::TimeoutError, attempts: 1)
  end

  it 'leaves the event untouched when the first attempt succeeds' do
    stub_request(:get, 'http://kb.test/v1/pets/k').to_return(json)

    client.find('k')

    expect(events.last).not_to include(:retries, :retry_errors)
  end
end
