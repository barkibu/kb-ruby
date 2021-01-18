shared_examples 'Localizable Request' do |method|
  around do |all|
    I18n.with_locale(:es) do
      all.run
    end
  end

  it 'passes locale as params' do
    stubs.public_send(method || :get, resource_path) do |env|
      expect(env.params).to include({ 'locale' => 'es' })
      api_response
    end

    subject
  end
end
