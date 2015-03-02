## Contributing to TimeSeries

The best way to contribute code is to fork the main repo and send a pull request on GitHub.  

Bug fixes should be done in the master branch. New features or major changes should be done in a feature branch.  Alternatively, you can send a plain-text patch to the [mailing list](https://groups.google.com/forum/#!forum/opentsdb-clients).

Please break down your changes into as many small commits as possible. 

Please respect the coding style of the code you're changing. TimeSeries uses Rubocop and reek to adhere to the Ruby style guide.

## Pull Request Requirements

*Before* sending a pull request, please make sure your changes meet the following criteria:

- You have run `bundle exec rake build` and your code:
    - Maintains code coverage remains at 100%
    - Has fully been fully documented (`yard` coverage at 100%)
    - Has no `reek` warnings
    - Has no `rubocop` warnings
    - All RSpec tests pass


