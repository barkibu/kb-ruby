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
- `all`
    - arg: `filters` hash of filters
    - returns: an array of PetParent instances matching the filters
- `save!`
    - persists (create or update) the entity to the Knowledge Base

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
