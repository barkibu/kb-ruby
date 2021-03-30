# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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

[Unreleased]: https://github.com/barkibu/kb-ruby/compare/v0.3.2...HEAD
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
