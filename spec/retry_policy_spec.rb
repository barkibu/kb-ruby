require 'spec_helper'

RSpec.describe KB::RetryPolicy do
  verbs = %i[get head post patch put delete]
  every_verb = verbs.to_h { |verb| [verb, true] }
  get_and_head_only = verbs.to_h { |verb| [verb, %i[get head].include?(verb)] }
  no_verb = verbs.to_h { |verb| [verb, false] }

  # Pins exactly which error x verb combinations retry.
  {
    'connect timeout (net_http adapter)' => [-> { Faraday::ConnectionFailed.new(Net::OpenTimeout.new) }, every_verb],
    'connect timeout (persistent adapter)' => [-> { Faraday::TimeoutError.new(Net::OpenTimeout.new) }, every_verb],
    'connection refused' => [-> { Faraday::ConnectionFailed.new(Errno::ECONNREFUSED.new) }, every_verb],
    'host unreachable' => [-> { Faraday::ConnectionFailed.new(Errno::EHOSTUNREACH.new) }, every_verb],
    'DNS failure' => [-> { Faraday::ConnectionFailed.new(SocketError.new) }, every_verb],
    'read timeout' => [-> { Faraday::TimeoutError.new(Net::ReadTimeout.new) }, get_and_head_only],
    'write timeout' => [-> { Faraday::TimeoutError.new(Net::WriteTimeout.new) }, get_and_head_only],
    'connection reset' => [-> { Faraday::ConnectionFailed.new(Errno::ECONNRESET.new) }, get_and_head_only],
    'EOF while awaiting headers' => [-> { Faraday::ConnectionFailed.new(EOFError.new) }, get_and_head_only],
    'TLS error' => [-> { Faraday::SSLError.new(OpenSSL::SSL::SSLError.new) }, get_and_head_only],
    'HTTP 404' => [-> { Faraday::ResourceNotFound.new('not found') }, no_verb],
    'HTTP 500' => [-> { Faraday::ServerError.new('boom') }, no_verb]
  }.each do |description, (build_error, expected)|
    it "retries a #{description} for exactly the pinned verbs" do
      error = build_error.call
      expect(verbs.to_h { |verb| [verb, described_class.retry?(verb, error)] }).to eq(expected)
    end
  end
end
