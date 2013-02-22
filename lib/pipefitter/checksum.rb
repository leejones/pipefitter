class Pipefitter
  class Checksum
    attr_reader :base_path

    def initialize(base_path, paths = nil)
      @base_path = base_path
      @paths = paths
    end

    def checksum
      `find #{paths.join(' ')} -type f -exec md5 -q {} + | md5 -q`.strip
    end

    def paths
      @paths ||= default_paths
    end

    def default_paths
      %w{./Gemfile ./Gemfile.lock app/assets lib/assets vendor/assets}.map do |path|
        File.join(base_path, path)
      end
    end
  end
end
