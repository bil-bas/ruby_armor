module RubyArmor
  class ChooseProfile < Fidgit::GuiState
    def setup
      super

      on_input :escape, :hide

      # Create the game.
      @game = RubyWarrior::Game.new

      warrior_sprites = SpriteSheet.new "warriors.png", Play::SPRITE_WIDTH, Play::SPRITE_HEIGHT, 4

      vertical align_h: :center, spacing: 30 do
        vertical align: :center, padding_top: 30, padding: 0 do
          label "ryanb's RubyWarrior is wearing Spooner's", font_height: 12
          label "RubyArmor", align: :center, font_height: 80
        end

        # Use existing profile.
        vertical padding: 0, align_h: :center do
          scroll_window height: 250, width: 460 do
            @game.profiles.each do |profile|
              config = WarriorConfig.new profile

              name_of_level = profile.epic? ? "EPIC" : profile.level_number.to_s
              title = "#{profile.warrior_name.ljust(20)} #{profile.tower.name.rjust(12)}:#{name_of_level[0, 1]} #{profile.score.to_s.rjust(5)}"
              tip = "Play as #{profile.warrior_name} the #{config.warrior_class.capitalize} - #{profile.tower.name} - level #{name_of_level} - score #{profile.score}"

              # Can be disabled because of a bug in RubyWarrior paths.
              button title, width: 400, tip: tip, enabled: File.directory?(profile.tower_path),
                            icon: warrior_sprites[0, Play::WARRIORS[config.warrior_class]], icon_options: { factor: 2 } do
                play profile, config
              end
            end
          end
        end

        # Option to create a new profile.
        horizontal align: :center do
          button "Create new profile", shortcut: :auto, shortcut_color: Play::SHORTCUT_COLOR do
            CreateProfile.new(@game, warrior_sprites).show
          end

          button "Exit", shortcut: :x, shortcut_color: Play::SHORTCUT_COLOR do
            exit!
          end
        end
      end
    end

    def finalize
      super
      container.clear
    end

    def play(profile, config)
      @game.instance_variable_set :@profile, profile
      push_game_state Play.new(@game, config)
    end
  end
end