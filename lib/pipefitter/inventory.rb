require 'yaml'
require 'fileutils'

class Pipefitter
  class Inventory 
    attr_reader :path

    def initialize(path)
      @path = path
      FileUtils.mkdir_p(path)
    end

    def put(key, value) 
      data[key] = value
      save
    end

    def get(key)
      data[key]
    end

    private
    
    def data
      @data ||= begin
        if File.exists?(data_file)
          YAML.load_file(data_file)
        else
          FileUtils.touch(data_file)
          {}
        end
      end
    end

    def data_file
      File.join(path, 'inventory.yml')
    end

    def save
      File.open(data_file, 'w+') do |file|
        file.write(data.to_yaml)
      end
    end
  end
end
