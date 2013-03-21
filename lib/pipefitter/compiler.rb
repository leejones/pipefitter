class Pipefitter
  class Compiler
    attr_reader :base_path

    def initialize(base_path, options = {})
      @options = options
      @base_path = base_path
    end

    def compile
      logger.info "Running `#{compile_command}`..."
      result = `cd #{base_path} && #{compile_command} 2>&1`.chomp
      status = $?.to_i == 0
      log_result(result, status)
      status
    end

    private

    def compile_command
      options.fetch(:command, default_compile_command)
    end

    def default_compile_command
      if using_bundler?
        'bundle exec rake assets:precompile'
      else
        'rake assets:precompile'
      end
    end

    def using_bundler?
      File.exists?(gemfile)
    end

    def gemfile
      gemfile = File.join(base_path, 'Gemfile')
    end

    def options
      @options
    end

    def log_result(result, status = true)
      if status
        logger.info result unless result == ''
      else
        logger.error result unless result == ''
      end
    end

    def logger
      @logger ||= options.fetch(:logger, Pipefitter::Logger.new)
    end
  end
end
