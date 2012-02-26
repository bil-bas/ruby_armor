require 'fileutils'

require_relative "base_user_data"

module RubyArmor
  class WarriorConfig < BaseUserData
    DEFAULT_CONFIG = File.expand_path "../../../config/default_config.yml", __FILE__
    OLD_CONFIG_FILE = "ruby_armour.yml"
    CONFIG_FILE = "ruby_armor/config.yml"

    def initialize(profile)
      # Originally, config file was just in the folder. Move into its own folder, so we can put more in there.
      old_config_file = File.join(profile.player_path, OLD_CONFIG_FILE)
      config_file = File.join(profile.player_path, CONFIG_FILE)
      if File.exists? old_config_file
        FileUtils.mkdir_p File.dirname(config_file)
        FileUtils.mv old_config_file, config_file
      end

      super config_file, DEFAULT_CONFIG
    end

    def turn_delay; data[:turn_delay]; end
    def turn_delay=(delay)
      data[:turn_delay] = delay
      save
    end

    def warrior_class; data[:warrior_class]; end
    def warrior_class=(warrior_class)
      data[:warrior_class] = warrior_class
      save
    end
  end
end