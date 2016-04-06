# v4.1.1
- Bumped Rubocop to `~> 0.28.0` and updated dependencies
- Fixed new Rubocop warnings

# v4.1.0
- Bumped RSpec to `~> 3.0`
- Updated tests to follow betterspecs.org guidelines
- Added integration tests using Docker

# v4.0.0
- Added initial support for synthetic metrics through formula calculations.
- Dropped OpenTSDB 1.1 support (includes dropping ASCII output support!)
- Dropped client-side validation support (done by OpenTSDB now)

# v3.0.0
- Updated response signatures to include status code, result count, and explicit error messages.

# v2.4.0
- Added multi-query support (persistent, pipelined HTTP requests)

# v2.3.0
- Deprecrated client-side validation for OpenTSDB 2.0 clients

# v2.2.0
- Switched to Excon from HTTParty

# v2.1.0
- Upgraded to Ruby 1.9.3

# v2.0.1
- Added proper rate support

# v2.0.0
- Initial OpenTSDB 2.0 support