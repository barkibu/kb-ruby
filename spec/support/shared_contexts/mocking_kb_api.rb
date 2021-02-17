shared_context 'with a mock as KB API' do
  require 'kb-fake'

  before(:all) do
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
  end

  around do |example|
    snapshot = KB::Fake::Api.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
    example.run
    KB::Fake::Api.restore snapshot
  end
end
