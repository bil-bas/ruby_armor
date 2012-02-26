module RubyArmor
  class ChooseProfile < Fidgit::GuiState
    DEFAULT_WARRIOR_CLASS = :valkyrie

    def setup
      super

      # Create the game.
      @game = RubyWarrior::Game.new

      warrior_sprites = SpriteSheet.new "warriors.png", Play::SPRITE_WIDTH, Play::SPRITE_HEIGHT, 4

      vertical align_h: :center, spacing: 50 do
        label "RubyArmor", align: :center, font_height: 120, padding_top: 50

        button_options = { width: 400, align: :center, justify: :center }

        # Use existing profile.
        vertical padding: 0, align_h: :center do
          scroll_window height: 200, width: 460 do
            @game.profiles.each do |profile|
              config = WarriorConfig.new profile

              title = "#{profile.warrior_name.ljust(20)} #{profile.tower.name.rjust(12)}:#{profile.level_number} #{profile.score.to_s.rjust(5)}"
              tip = "Play as #{profile.warrior_name} the #{config.warrior_class.capitalize} - #{profile.tower.name} - level #{profile.level_number} - score #{profile.score}"

              # Can be disabled because of a bug in RubyWarrior paths.
              button title, button_options.merge(tip: tip, enabled: File.directory?(profile.tower_path),
                                                 icon: warrior_sprites[0, Play::WARRIORS[config.warrior_class]], icon_options: { factor: 2 }) do
                play profile, config
              end
            end
          end
        end

        # Option to create a new profile.
        vertical padding: 0, align: :center do
          horizontal align: :center, padding: 0 do
            @new_name = text_area width: 300, max_height: 60, font_height: 24 do |_, text|
              duplicate = @game.profiles.any? {|p| p.warrior_name.downcase == text.downcase }
              @new_profile_button.enabled = !(text.empty? or duplicate)
            end

            @new_profile_button = button "New", button_options.merge(width: 90, tip: "Create a new profile") do
              play *new_profile(@new_name.text)
            end

            new_name = File.basename File.expand_path("~")
            new_name = "Player" if new_name.empty?
            @new_name.text = new_name
          end

          # Choose class; just cosmetic.
          @warrior_class = group align_h: :center do
            horizontal padding: 0, align_h: :center do
              Play::WARRIORS.each do |warrior, row|
                radio_button "", warrior, tip: "Play as a #{warrior.capitalize} (The difference between classes is purely cosmetic!)",
                             :icon => warrior_sprites[0, row], :icon_options => { :factor => 4 }
              end
            end
          end

          @warrior_class.value = DEFAULT_WARRIOR_CLASS
        end
      end
    end

    def play(profile, config)
      @game.instance_variable_set :@profile, profile
      push_game_state Play.new(@game, config)
    end

    def new_profile(name)
      new_profile = RubyWarrior::Profile.new
      new_profile.tower_path = @game.towers[0].path
      new_profile.warrior_name = name

      config = WarriorConfig.new new_profile
      config.warrior_class = @warrior_class.value

      [new_profile, config]
    end
  end
end