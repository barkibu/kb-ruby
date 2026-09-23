require 'socket'

# A tiny HTTP/1.1 server on a real socket that keeps connections open, for specs
# that need to see connection reuse. Counts accepted TCP connections.
#
#   GET .../stall  reads the request and never answers
#   GET .../close  answers, then closes the connection without saying so
#   anything else  answers 200 {"ok":true}
class KeepAliveServer
  attr_reader :accepted

  def initialize
    @server = TCPServer.new('127.0.0.1', 0)
    @accepted = 0
    @threads = []
    @acceptor = Thread.new { accept_loop }
  end

  def port
    @server.addr[1]
  end

  def stop
    @server.close
    @acceptor.join(1)
    @threads.each { |thread| thread.kill.join(1) }
  end

  private

  def accept_loop
    loop do
      socket = @server.accept
      @accepted += 1
      @threads << Thread.new(socket) { |client| serve(client) }
    end
  rescue IOError, Errno::EBADF
    nil
  end

  def serve(socket)
    while (path = read_request(socket))
      return sleep if path.end_with?('/stall')

      respond(socket)
      return socket.close if path.end_with?('/close')
    end
  rescue IOError, Errno::ECONNRESET, Errno::EPIPE
    nil
  ensure
    socket.close unless socket.closed?
  end

  def read_request(socket)
    request_line = socket.gets
    return nil if request_line.nil?

    length = 0
    while (line = socket.gets) && line != "\r\n"
      length = line.split(':', 2).last.to_i if line.downcase.start_with?('content-length:')
    end
    socket.read(length) if length.positive?
    request_line.split[1]
  end

  def respond(socket)
    body = '{"ok":true}'
    socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
                 "Content-Length: #{body.bytesize}\r\n\r\n#{body}")
  end
end
