# Barkibu's Knowledge Base API sdk

A wrapper of Barkibu's Knowledge Base Endpoint to make those entities and their respective CRUD operations available to a ruby app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kb

## Usage

This gem wraps the Knowledge Base Api and exposes CRUD-_able_ entities into the requiring application.

### Configuration

The configuration of the connection to the Knowledge Base is done using ENV variable:

- **KB_API_KEY**: the Knowledge Base API Key
- **KB_PARTNER_KEY**: the Partner KB Key
- **KB_API_URL_TEMPLATE**: the template url of the Knowledge Base where will be extrapolated _bounded_context_, _version_ and _entity_.

  For instance: `https://dev.api.%{bounded_context}.barkkb.com/%{version}/%{entity}`.

### Exposed Entities

#### Pet Parent 🧍🏾

`KB::PetParent` acts almost like an `ActiveRecord` implementing `ActiveModel::Model` exposing:

- `find`
  - arg: `key` string
  - returns: a PetParent instance when provided an existing key or raise `ActiveRecord::RecordNotFound`
- `create`
  - arg: `attributes` to initialize the entity 
  - returns: the raw attributes of the created PetParent instance
  - throws an `KB::Error` exception if something went wrong
- `find_or_create_by`
  - arg: `attributes`, `additional_attributes` to look for or initialize the entity 
  - returns: look for a PetParent matching the passed attributes or initialize and persist one with the given attributes and launching the block provided
  - throws an `KB::Error` exception if something went wrong
- `all`
  - arg: `filters` hash of filters
  - returns: an array of PetParent instances matching the filters
- `save!`
  - persists (create or update) the entity to the Knowledge Base
  - throws an `KB::Error` exception if something went wrong


#### Assessment 📄

`KB::Assessment` represents a read-only resource exposing:

- `find`
  - arg: `key` string
  - returns: an Assessment instance when provided an existing key or raise `ActiveRecord::RecordNotFound`
- `all`
  - arg: `filters` hash of filters
  - returns: an array of Assessment instances matching the filters

#### Condition 🏷

`KB::Condition` represents a read-only resource.

#### Symptom 🩺

`KB::Symptom` represents a read-only resource.

#### Pet 🐶🐱

`KB::Pet` represents a resource exposing:

- `all`
  - arg: `filters` hash of filters
  - returns: an array of Pet instances matching the filters
- `create`
  - arg: `attributes` to initialize the entity 
  - returns: the raw attributes of the Pet instance
  - throws an `KB::Error` exception if something went wrong
- `find_or_create_by`
  - arg: `attributes`, `additional_attributes` to look for or initialize the entity 
  - returns: look for a Pet matching the passed attributes or initialize and persist one with the given attributes and launching the block provided
  - throws an `KB::Error` exception if something went wrong
#### Breed

```
> KB Breed endpoint requires `locale` as param. By default is set to 'es-es' but can be override setting **KB_BREEDS_DEFAULT_LOCALE** ENV var
```

`KB::Breed` represents a resource exposing:

- `all`
  - arg: `filters` hash of filters
  - returns: and array of Breed instances matching the filters
- `dogs` (alias for all(species: 'dog'))
  - arg: `filters` hash of filters
  - returns: and array of Dog Breed instances matching the filters
- `cats` (alias for all(species: 'cat'))
  - arg: `filters` hash of filters
  - returns: and array of Cat Breed instances matching the filters

### Make an ActiveRecord wrap a KB entity

The `KB::Concerns::AsKBWrapper` concern has been created in order to easily make an ActiveRecord model wrap a KB model.

To use it:
- include it into your wrapping model, define an attribute `kb_key` on your wrapping model 
- call `wrap_kb` with the wrapped KB model class (available option: `skip_callback`)

You have then access to the wrapped model under `kb_model` and can delegate attributes to it, for instance:

```ruby
class User < ActiveRecord::Base
  include KB::Concerns::AsKBWrapper

  wrap_kb model: KB::PetParent

  KB_DELEGATED_ATTRIBUTES = %i[email first_name].freeze

  KB_DELEGATED_ATTRIBUTES.each do |attribute|
    delegate attribute, to: :kb_model, prefix: false
    delegate "#{attribute}=", to: :kb_model, prefix: false
  end
end

user = User.create(first_name: 'Léo', email: 'leo@barkibu.com')
p user.kb_model
# => #<KB::PetParent: 0x000055fd72d32c30 key: "373ad90e-c2ce-46cb-9749-deb2b03be995", first_name: "Léo", ..., email: "leo@barkibu.com">
```

### Mock the API calls in test environment

For testing purposes, you may want to fake Knowledge Base’s API calls. We provide a FakeApi app that you can use including kb/tests.

Add gem webmock and gem sinatra to your Gemfile to use the following configuration:

```ruby
    require 'kb/tests'
    # ...

    RSpec.configure do |config|
        # ...
        config.before(:all) do
            stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
        end

        config.around(:each) do |example|
            snapshot = KB::Tests::FakeApi.snapshot()
            stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
            example.run
            KB::Tests::FakeApi.restore snapshot
        end
        # ...
    end
```

Make sure to set the `KB_API_URL_TEMPLATE` to something that will match above the request interceptor, for instance: `http://test_api_barkkb.com/%{version}/%{entity}`

You should be able to use the API seemlessly and the calls to the API will be intercepted and a local one used instead in a similar fashion to how ActiveRecord operations are wrapped into a transaction in a rails app with `use_transactional_fixtures` activated.

## Development & Testing

```bash
    docker run -it --rm -v $(pwd):/app --workdir=/app ruby:2.6.5 bash

    > bundle install
    > rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KB project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kb/blob/master/CODE_OF_CONDUCT.md).
