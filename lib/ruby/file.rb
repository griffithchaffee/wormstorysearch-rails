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
      parse_yaml_content(parse_erb_content(read_file(file)))
    end

    def load_rails_config_file(filename)
      load_config_file("#{Rails.root}/config/#{filename}")
    end

    def file_directory(file)
      File.expand_path(File.dirname(file))
    end
  end
end
