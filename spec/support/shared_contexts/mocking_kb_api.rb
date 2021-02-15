shared_context 'with a mock as KB API' do
  require 'kb/fake'

  before(:all) do
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::FakeApi)
  end

  around do |example|
    snapshot = KB::Fake::FakeApi.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::FakeApi)
    example.run
    KB::Fake::FakeApi.restore snapshot
  end
end
