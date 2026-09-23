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

  it "does not leak one call's read_timeout override into the next call on the same connection" do
    KB.config.request.read_timeout = 1
    client.request('a', read_timeout: 30)

    seconds = elapsed { client.request('stall') }

    # Two attempts at the 1s global budget (the retry gets a fresh connection),
    # not 30s: the override stayed with the call that asked for it.
    expect(within_global_budget: seconds < 5, connections: events.last[:connections])
      .to eq(within_global_budget: true, connections: %w[reused new])
  ensure
    KB.config.request.read_timeout = 5
  end

  it 'recovers when the server closed an idle connection without telling the client' do
    client.request('close')

    expect(result: client.request('a'), accepted: server.accepted).to eq(result: { 'ok' => true }, accepted: 2)
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

    expect(error: error.class, cause: KB::RetryPolicy.root_cause(error).class, retried: events.last[:retry_errors])
      .to eq(error: Faraday::ConnectionFailed, cause: Errno::ECONNREFUSED, retried: ['Errno::ECONNREFUSED'])
  ensure
    KB.config.request.retry_interval = 0.1
  end
end
