class Pipefitter
  class Compiler
    attr_reader :base_path

    def initialize(base_path, options = {})
      @options = {} 
      @base_path = base_path
    end

    def compile
      # TODO: capture errors to report later to the user
      `cd #{base_path} && #{compile_command} 2>&1`
      $?.to_i == 0
    end

    private

    def compile_command
      options.fetch(:command, 'rake assets:precompile') 
    end

    def options
      @options
    end
  end
end
