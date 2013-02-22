# Pipefitter

A tool for the asset pipeline for avoiding unnecessary compilation runs.

## Installation

Add this line to your application's Gemfile:

    gem 'pipefitter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pipefitter

## Usage

### compile assets

Pipefitter is a smart wrapper for your assets compilation task. Run it to
compile your assets:

    pipefitter compile
    Asset changes detected, compiling assets...
    Asset compilation completed!

Then, you can run Pipefitter again to see if anything needs to be compiled:

    pipefitter compile
    No asset changes detected, you're good to go!

If you are running into problems, you can force asset compilation:

    pipefitter compile --force

By default, pipefitter runs `rake assets:precompile`. If you need to run a custom
script or rake task you can pass the `--command` option:

    pipefitter command --command "script/custom_compile"



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
