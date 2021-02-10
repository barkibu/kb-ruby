# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/barkibu/kb-ruby/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/barkibu/kb-ruby/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/barkibu/kb-ruby/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/barkibu/kb-ruby/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/barkibu/kb-ruby/releases/tag/v0.1.1
