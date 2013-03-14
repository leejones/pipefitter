require 'logger'

class Pipefitter
  class Logger < ::Logger
    def initialize(logger = STDOUT)
      super(logger)
      original_formatter = ::Logger::Formatter.new
      self.formatter = proc { |severity, datetime, progname, message|
        "#{message}\n"
      }
      self
    end
  end
end
