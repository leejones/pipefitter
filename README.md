# Pipefitter

A command-line tool that avoids unnecessary compiles when using the Rails Asset Pipeline.

## Installation

Add this line to your application's Gemfile:

    gem 'pipefitter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pipefitter

## Usage

The `pipefitter` command is a smart wrapper to use when compiling your assets:

    $ pipefitter
    Running `bundle exec rake assets:precompile`...
    Finished compiling assets!

It will automatically check if something changed that would require another compile:

    $ pipefitter
    Skipped compile because no changes were detected.

You can archive a compile in case it can be reused later (ex. switching back and forth between branches)

    $ pipefitter --archive
    $ rm -rf public/assets # oh no!
    $ pipefitter
    Used compiled assests from local archive!
    # boom. didn't even need to recompile

Run a custom compile command:

    $ pipefitter --command script/awesome_compile
    Running `script/awesome_compile`...
    Finished compiling assets!

If something seems out of sorts with the change detection, you can force asset compilation:

    $ pipefitter --force
    Running `bundle exec rake assets:precompile`...
    Finished compiling assets!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
