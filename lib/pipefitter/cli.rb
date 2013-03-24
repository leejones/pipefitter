require 'logger'

class Pipefitter
  class Cli
    attr_reader :arguments

    def self.run(arguments, options = {})
      new(arguments, options).run
    end

    def initialize(arguments, options = {})
      @arguments = arguments
      @options = options
    end

    def run
      if help_requested?
        logger.info help_text
      else
        Pipefitter.compile(path, compiler_options)
      end
    end

    private

    def path
      path_argument || environment.fetch(:PWD)
    end

    def path_argument
      arguments.reject do |arg|
        arg =~ /\A\-\-/ || arg == command_argument
      end.first
    end

    def environment
      @environment ||= begin
        environment = options.fetch(:environment)
        symbolize_keys(environment)
      end
    end

    def compiler_options
      c_options = { :logger => logger }
      if arguments.include?('--force')
        c_options[:force] = true
      end
      if arguments.include?('--archive')
        c_options[:archive] = true
      end
      if arguments.include?('--command')
        c_options[:command] = command_argument
      end
      c_options
    end

    def options
      @options_with_symbolized_keys ||= symbolize_keys(@options)
    end

    def command_argument
      @command_argument ||= begin
        if arguments.include?('--command')
          arguments[arguments.index('--command') + 1]
        else
          nil
        end
      end
    end

    def symbolize_keys(hash)
      hash.inject({}) do |memo, (k, v)|
        memo[k.to_sym] = v
        memo
      end
    end

    def logger
      @logger ||= options.fetch(:logger, Pipefitter::Logger.new)
    end

    def help_requested?
      arguments.include?('--help')
    end

    def help_text
      <<-EOS
# Pipefitter

## Usage

    pipefitter [project path] [options]

### Arguments

* project root - optional project path to compile (default: current working directory)
* --force - forces a compile even when none is needed
* --archive - archives the compile assets to tmp in the project root
* --help - this help text :)
EOS

    end
  end
end
