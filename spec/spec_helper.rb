require 'pathname'
require 'bundler/setup'
require 'webmock/rspec'
require 'simplecov'

SimpleCov.profiles.define 'kb' do
  add_filter '/bin/'
  add_filter '/spec/'

  add_group 'Models', 'lib/kb/models'
  add_group 'Concerns', 'lib/kb/concerns'
  add_group 'Fake', 'lib/kb/fake'
  add_group 'Type', 'lib/kb/type'
  add_group 'Validator', 'lib/kb/validator'
  add_group 'Client', ['lib/kb/client', 'lib/kb/client_resolver']
end

SimpleCov.start 'kb'

require 'kb'

gem_root = Pathname.new('..').expand_path(File.dirname(__FILE__))
Dir[gem_root.join('spec/support/**/*.rb')].sort.each { |f| require f }

ENV['KB_API_URL_TEMPLATE'] = 'https://test.api.%<bounded_context>s.test_api_barkkb.com/%<version>s/%<entity>s'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
