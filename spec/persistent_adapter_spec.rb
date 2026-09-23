require 'spec_helper'

# End-to-end on a real socket, with WebMock fully disabled: its Net::HTTP patch
# opens a new socket for every real request, which would hide connection reuse.
RSpec.describe KB::PersistentAdapter do
  let(:server) { KeepAliveServer.new }
  let(:base_url) { "http://127.0.0.1:#{server.port}/v1/pets" }
  let(:client) { KB::Client.new(base_url, api_key: 'test') }
  let(:events) { [] }

  around do |example|
    WebMock.disable!
    subscriber = ActiveSupport::Notifications.subscribe(KB::Client::REQUEST_EVENT) { |*, p| events << p }
    described_class.reset!
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
    described_class.reset!
    WebMock.enable!
    server.stop
  end

  def failure
    yield
    nil
  rescue Faraday::Error => e
    e
  end

  def elapsed(&block)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    failure(&block)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  it 'is the default adapter' do
    expect(client.send(:connection).adapter).to eq described_class
  end

  it 'reuses one TCP connection across calls and reports it on the event' do
    3.times { client.request('a') }

    expect(accepted: server.accepted, connections: events.map { |e| e[:connections] })
      .to eq(accepted: 1, connections: [['new'], ['reused'], ['reused']])
  end

  it 'shares the pool between clients of different entities on the same host' do
    client.request('a')
    KB::Client.new("http://127.0.0.1:#{server.port}/v1/petparents", api_key: 'test').request('b')

    expect(server.accepted).to eq 1
  end

  it 'reuses connections for writes too' do
    client.request('a')
    client.create(name: 'Rex')

    expect(accepted: server.accepted, write: events.last[:connections]).to eq(accepted: 1, write: ['reused'])
  end

  context "with one call's read_timeout override" do
    around do |example|
      KB.config.request.read_timeout = 1
      KB.config.request.retries = 0
      example.run
    ensure
      KB.config.request.read_timeout = 5
      KB.config.request.retries = 1
    end

    # The stock adapter writes each call's timeouts onto the shared
    # Net::HTTP::Persistent, where any thread's next checkout picks them up.
    it 'never writes it onto the shared Net::HTTP::Persistent' do
      client.request('a', read_timeout: 30)

      expect(described_class.http.read_timeout).to be_nil
    end

    it 'keeps it on its own connection while another thread uses the global budget' do
      slow = Thread.new { client.request('slow', read_timeout: 30) } # 2s answer, over the 1s global
      sleep 0.3 # let it check its connection out first

      seconds = elapsed { client.request('stall') }

      expect(stalled_within_global_budget: seconds < 2.5, slow_result: slow.value, accepted: server.accepted)
        .to eq(stalled_within_global_budget: true, slow_result: { 'ok' => true }, accepted: 2)
    end
  end

  # A POST is not retried after a maybe-sent failure, so this passes only if the
  # closed connection is detected before the request is written.
  it 'detects a connection the server closed without telling the client, before sending on it' do
    client.request('close')

    result = client.create(name: 'Rex')

    expect(result: result, retries: events.last[:retries], accepted: server.accepted)
      .to eq(result: { 'ok' => true }, retries: nil, accepted: 2)
  end

  # The stock configure_ssl sets a cert store per adapter instance (per model
  # client); every change bumps ssl_generation, which drops all TLS connections.
  it 'never re-applies SSL settings, whichever client makes the call' do
    client.request('a')
    KB::Client.new("http://127.0.0.1:#{server.port}/v1/petparents", api_key: 'test').request('b')
    client.request('a')

    expect(described_class.http.ssl_generation).to eq 0
  end

  it 'connects with the configured connect_timeout' do
    client.request('a')

    expect(described_class.http.open_timeout).to eq KB.config.request.connect_timeout
  end

  context 'with a short idle_timeout' do
    around do |example|
      KB.config.request.idle_timeout = 0.2
      example.run
    ensure
      KB.config.request.idle_timeout = 30
    end

    it 'opens a new connection once the pooled one has been idle too long' do
      client.request('a')
      sleep 0.4

      expect { client.request('a') }.to change(server, :accepted).from(1).to(2)
    end
  end

  it 'keeps the net_http error contract: connection refused is a retried ConnectionFailed' do
    closed_port = TCPServer.open('127.0.0.1', 0) { |s| s.addr[1] }
    refused = KB::Client.new("http://127.0.0.1:#{closed_port}/v1/pets", api_key: 'test')
    KB.config.request.retry_interval = 0

    error = failure { refused.request('a') }

    expect(error: error.class, cause: KB::RetryPolicy.root_cause(error).class, retried: events.last[:retry_errors],
           connections: events.last[:connections])
      .to eq(error: Faraday::ConnectionFailed, cause: Errno::ECONNREFUSED, retried: ['Errno::ECONNREFUSED'],
             connections: %w[new new])
  ensure
    KB.config.request.retry_interval = 0.1
  end
end
