class Pipefitter
  class Compressor
    attr_reader :base_path

    def initialize(base_path, target_path = nil)
      @base_path = base_path
    end

    def compress(filename = nil)
      `cd #{base_path}/public && tar -czf #{target(filename)} #{source}`
    end

    private

    def source
      './assets'
    end

    def target(filename = nil)
      target_filename = filename || default_target_filename
      File.join(target_path, target_filename)
    end

    def target_path
      @target_path ||= begin
        File.join(base_path, 'tmp', 'pipefitter')
      end
    end

    def default_target_filename
      "#{Time.now.to_i}.tar.gz"
    end
  end
end
