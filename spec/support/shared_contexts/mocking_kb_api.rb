shared_context 'with a mock as KB API' do
  require 'kb/tests'

  before(:all) do
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
  end

  around do |example|
    snapshot = KB::Tests::FakeApi.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
    example.run
    KB::Tests::FakeApi.restore snapshot
  end
end
