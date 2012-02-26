require_relative "base_user_data"

module RubyArmor
  class WarriorConfig < BaseUserData
    DEFAULT_CONFIG = File.expand_path "../../../config/default_config.yml", __FILE__
    CONFIG_FILE = "ruby_armour.yml"

    def initialize(profile)
      super File.join(profile.player_path, CONFIG_FILE), DEFAULT_CONFIG
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