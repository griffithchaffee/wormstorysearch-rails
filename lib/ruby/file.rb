class File::Configuration
  class << self
    def read_file(file)
      File.read(file)
    end

    def parse_erb_content(content)
      ERB.new(content).result
    end

    def parse_yaml_content(content)
      YAML.load(content)
    end

    def load_config_file(file)
      content = read_file(file)
      file.split(".").reverse.each do |extension|
        case extension
        when "erb" then content = parse_erb_content(content)
        when "yml" then content = parse_yaml_content(content)
        end
      end
      content
    end

    def load_rails_config_file(filename)
      load_config_file("#{Rails.root}/config/#{filename}")
    end

    def file_directory(file)
      File.expand_path(File.dirname(file))
    end
  end
end
