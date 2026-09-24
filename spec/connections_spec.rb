require 'spec_helper'

# End-to-end on a real socket, with WebMock fully disabled: its Net::HTTP patch
# opens a new socket for every real request, which would hide connection reuse.
# `server.accepted` counts TCP connections the server accepted.
RSpec.describe KB::Connections do
  let(:server) { KeepAliveServer.new }
  let(:client) { KB::Client.new("http://127.0.0.1:#{server.port}/v1/pets", api_key: 'test') }
  let(:events) { [] }

  around do |example|
    WebMock.disable!
    subscriber = ActiveSupport::Notifications.subscribe(KB::Client::REQUEST_EVENT) { |*, p| events << p }
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
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

  it 'reuses one TCP connection across calls' do
    3.times { client.request('a') }

    expect(server.accepted).to eq 1
  end

  it 'shares the connection between clients of different entities on the same host' do
    client.request('a')
    KB::Client.new("http://127.0.0.1:#{server.port}/v1/petparents", api_key: 'test').request('b')

    expect(server.accepted).to eq 1
  end

  it 'reuses connections for writes too' do
    client.request('a')
    client.create(name: 'Rex')

    expect(server.accepted).to eq 1
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

  # A POST is not retried after a maybe-sent failure, so this passes only if the
  # closed connection is detected before the request is written. The short sleep
  # lets the server's FIN arrive, as it long has when the router closes an idle
  # connection; a close racing the write in the same instant is the next case.
  it 'detects a connection the server closed without telling the client, before sending on it' do
    client.request('close')
    sleep 0.2

    result = client.create(name: 'Rex')

    expect(result: result, retries: events.last[:retries], accepted: server.accepted)
      .to eq(result: { 'ok' => true }, retries: nil, accepted: 2)
  end

  context 'when the server drops a reused connection while the request is on it' do
    before do
      KB.config.request.retry_interval = 0
      client.request('a')
    end

    after { KB.config.request.retry_interval = 0.1 }

    it 'retries a GET once, on a fresh connection' do
      result = client.request('flaky')

      expect(result: result, retry_errors: events.last[:retry_errors], accepted: server.accepted)
        .to eq(result: { 'ok' => true }, retry_errors: ['EOFError'], accepted: 2)
    end

    it 'fails a POST without retrying it, since KB may have processed it' do
      error = failure { client.request('flaky', filters: {}, method: :post) }

      expect(error: error.class, cause: KB::RetryPolicy.root_cause(error).class, retries: events.last[:retries])
        .to eq(error: Faraday::ConnectionFailed, cause: EOFError, retries: nil)
    end
  end

  context 'with a 1s global read budget and retries off' do
    around do |example|
      KB.config.request.read_timeout = 1
      KB.config.request.retries = 0
      example.run
    ensure
      KB.config.request.read_timeout = 5
      KB.config.request.retries = 1
    end

    # Net::HTTP would resend an idempotent PUT on a fresh connection by itself if
    # its max_retries were not 0, doubling an upsert behind KB::RetryPolicy's back.
    it 'sends a timed-out PUT once: Net::HTTP never retries on its own' do
      error = failure { client.request('stall', filters: {}, method: :put) }

      expect(error: error.class, accepted: server.accepted).to eq(error: Faraday::TimeoutError, accepted: 1)
    end

    it "keeps one call's read_timeout off the pooled calls of another thread" do
      slow = Thread.new { client.request('slow', read_timeout: 30) } # 2s answer, over the 1s global
      sleep 0.3 # let it send first

      seconds = elapsed { client.request('stall') }

      expect(stalled_within_global_budget: seconds < 2.5, slow_result: slow.value)
        .to eq(stalled_within_global_budget: true, slow_result: { 'ok' => true })
    end
  end

  it 'retries a GET whose connection was refused' do
    closed_port = TCPServer.open('127.0.0.1', 0) { |s| s.addr[1] }
    refused = KB::Client.new("http://127.0.0.1:#{closed_port}/v1/pets", api_key: 'test')
    KB.config.request.retry_interval = 0

    error = failure { refused.request('a') }

    expect(error: error.class, retries: events.last[:retries]).to eq(error: Faraday::ConnectionFailed, retries: 1)
  ensure
    KB.config.request.retry_interval = 0.1
  end
end
