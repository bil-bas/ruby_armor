module RubyArmor
  class BaseUserData
    #include Log

    def initialize(user_file, default_file)
      @user_file = user_file

      @data = if File.exists?(@user_file)
                begin
                  YAML.load_file @user_file
                rescue Psych::SyntaxError                  #log.warn { "Failed to load #{@user_file}; cleared settings" }

                  {}
                end
              else
                {}
              end

      @data = YAML.load_file(default_file).deep_merge @data

      #log.info { "Read and merged user data:\n#{@data}" }

      save
    end

    protected
    def data; @data; end

    protected
    def save
      FileUtils.mkdir_p File.dirname(@user_file)

      File.open(@user_file, "w") {|f| YAML.dump(@data, f) }

      #log.info { "Saved #{File.basename(@user_file)}" }
    end
  end
end