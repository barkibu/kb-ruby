require 'spec_helper'
require 'socket'

# End-to-end check that a per-request read timeout reaches the socket. A local
# TCP server accepts the connection, reads the request and never answers, so
# the only thing that can end the call is Net::HTTP's read timeout.
RSpec.describe KB::Client, '#request' do
  let(:server) { TCPServer.new('127.0.0.1', 0) }
  let(:port) { server.addr[1] }
  let(:client) { described_class.new("http://127.0.0.1:#{port}/v1/pets", api_key: 'test') }

  let!(:stalled_server) do
    Thread.new do
      loop do
        socket = server.accept
        socket.readpartial(4096) # consume the request, then stay silent
      rescue IOError, Errno::EBADF
        break
      end
    end
  end

  around do |example|
    WebMock.allow_net_connect!(net_http_connect_on_start: false)
    example.run
  ensure
    WebMock.disable_net_connect!
  end

  after do
    server.close
    stalled_server.join(1)
  end

  def elapsed
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  it 'gives up after the per-request read timeout, not the 5s global default' do
    error = nil
    seconds = elapsed do
      client.request('birthdays', filters: { month: 9 }, read_timeout: 1)
    rescue Faraday::Error => e
      error = e
    end

    expect(error: error.class, within_budget: seconds.between?(0.9, 2.5))
      .to eq(error: Faraday::TimeoutError, within_budget: true)
  end
end
