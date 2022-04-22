# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.14.3]
- Add `husbpot_id` attribute on PetContract

## [0.14.2]
- Fix Merged Pet Parent instanciation

## [0.14.1]
- Convert API exception into KB::Error for admin `merge!` endpoint

## [0.14.0]
- Add admin `merge!` method on PetParent

## [0.13.0]
- Add `affiliate_code`  attribute on PetParent

## [0.12.0]
- Add `phone_number_verified` and `email_verified` attributes on PetParent

## [0.11.0]
- Expose product_key on PetContract

## [0.10.0]
- Add KB::Product Entity

## [0.9.0]
- Add conversion_utm_adgroup_id and conversion_utm_campaign_id to PetContract

## [0.8.0]
- Add conversion_utm_\* attributes to PetContract

## [0.7.2]
- Fix kb-fake pet parent upsert with partial identification

## [0.7.1]
- Fix dsl-configurable positional arg deprecated warning

## [0.7.0]
- Add new Error classes
- Emulate the same behavior on Pet Parent Upsert

## [0.6.0]
- Add price_discount_yearly PetContract attribute

## [0.5.0]
- Switch to consume petfamily based consultation endpoint

## [0.4.10]
- Add affiliate PetContract attributes

## [0.4.9]
- Fix ActiveModel dirty implementation

## [0.4.8]
- Fix KB::Error not accepting nil body

## [0.4.7]
- Breed - Add external_id field

## [0.4.6]
- PetParent - Add more KB fields

## [0.4.5]
- Breeds - Add server endpoint for tests on fake gem

## [0.4.4]
- Breeds - Adjust fields definition to petfamily domain ones

## [0.4.3]
- Breeds - Change client resolver template to use petfamily domain

## [0.4.2]
- Assessment - Parse time from date

## [0.4.1]
- Add Pet Upsert method

## [0.4.0]
- Add Upsert Endpoint

## [0.3.6]
- Add cache to client request method

## [0.3.5]
- Add Dry gem and setup config
- Add cache as gem config settings
- Add log level as gem config settings
- Improve KB Exceptions definitions

## [0.3.4]
- Fix planName attributes wrongly named on Plan

## [0.3.3]
- Fix buyable and planLifeInMonths attributes wrongly named on Plan

## [0.3.2]
- Exposes `KB::PetContract` entity
- Add `contracts` method to `KB::Pet` and `KB::PetParent`

## [0.3.1]
- Fix Fake Consultation wrong endpoint version

## [0.3.0]
- Extracted `kb-fake` gem for client test purposes

## [0.2.7]
- Fix missing deleted_at accessors on PetParent and Pet entities

## [0.2.6]
- Exposes `Destroyable` concerns on PetParent and Pet entities

## [0.2.5]
- Exposes `FindOrCreatable` concerns on PetParent and Pet entities

## [0.2.4]
- Fix Assessment not properly localized

## [0.2.3]
- Fix missing ActiveSupport dependency loading

## [0.2.2]
- Fix custom array types returning single element
- Test dependency extracted

## [0.2.1]
- Fix gem loading order for tests

## [0.2.0]
- Provide FakeApi for client implementation testing
- Add Pet entity
- Add `AsKBWrapper` concern for easy activerecord wrapping
- Add `UniquenessValidator` for easy validation on wrapping model
- `AsKBWrapper` - add `skip_callback` option

## [0.1.1] - 2020-01-12
- Init Version: Breeds and limited PetParents/Consultations

[Unreleased]: https://github.com/barkibu/kb-ruby/compare/v0.10.0...HEAD
[0.10.0]: https://github.com/barkibu/kb-ruby/compare/v0.9.0...0.10.0
[0.9.0]: https://github.com/barkibu/kb-ruby/compare/v0.8.0...0.9.0
[0.8.0]: https://github.com/barkibu/kb-ruby/compare/v0.7.2...0.8.0
[0.7.2]: https://github.com/barkibu/kb-ruby/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/barkibu/kb-ruby/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/barkibu/kb-ruby/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/barkibu/kb-ruby/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/barkibu/kb-ruby/compare/v0.4.10...v0.5.0
[0.4.10]: https://github.com/barkibu/kb-ruby/compare/v0.4.9...v0.4.10
[0.4.9]: https://github.com/barkibu/kb-ruby/compare/v0.4.8...v0.4.9
[0.4.8]: https://github.com/barkibu/kb-ruby/compare/v0.4.7...v0.4.8
[0.4.7]: https://github.com/barkibu/kb-ruby/compare/v0.4.6...v0.4.7
[0.4.6]: https://github.com/barkibu/kb-ruby/compare/v0.4.5...v0.4.6
[0.4.5]: https://github.com/barkibu/kb-ruby/compare/v0.4.4...v0.4.5
[0.4.4]: https://github.com/barkibu/kb-ruby/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/barkibu/kb-ruby/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/barkibu/kb-ruby/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/barkibu/kb-ruby/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/barkibu/kb-ruby/compare/v0.3.6...v0.4.0
[0.3.6]: https://github.com/barkibu/kb-ruby/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/barkibu/kb-ruby/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/barkibu/kb-ruby/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/barkibu/kb-ruby/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/barkibu/kb-ruby/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/barkibu/kb-ruby/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/barkibu/kb-ruby/compare/v0.2.7...v0.3.0
[0.2.7]: https://github.com/barkibu/kb-ruby/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/barkibu/kb-ruby/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/barkibu/kb-ruby/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/barkibu/kb-ruby/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/barkibu/kb-ruby/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/barkibu/kb-ruby/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/barkibu/kb-ruby/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/barkibu/kb-ruby/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/barkibu/kb-ruby/releases/tag/v0.1.1
