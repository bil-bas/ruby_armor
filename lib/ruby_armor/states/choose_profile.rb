module RubyArmor
  class ChooseProfile < Fidgit::GuiState
    def setup
      super

      # Create the game.
      @game = RubyWarrior::Game.new

      vertical align_h: :center, spacing: 50 do
        label "RubyArmor", align: :center, font_height: 120, padding_top: 50

        button_options = { width: 400, align: :center, justify: :center }

        # Use existing profile.
        vertical padding: 0, align_h: :center do
          @game.profiles.each do |profile|
            title = "#{profile.warrior_name.ljust(20)} #{profile.tower.name.rjust(12)}:#{profile.level_number} #{profile.score.to_s.rjust(5)}"
            tip = "Play as #{profile.warrior_name} - #{profile.tower.name} - level #{profile.level_number} - score #{profile.score}"
            # Can be disabled because of a bug in RubyWarrior paths.
            button title, button_options.merge(tip: tip, enabled: File.directory?(profile.tower_path)) do
              play profile
            end
          end
        end

        # Option to create a new profile.
        horizontal align: :center, padding: 0 do
          @new_name = text_area width: 300, max_height: 60, font_height: 24 do |_, text|
            duplicate = @game.profiles.any? {|p| p.warrior_name.downcase == text.downcase }
            @new_profile_button.enabled = !(text.empty? or duplicate)
          end

          @new_profile_button = button "New", button_options.merge(width: 90, tip: "Create a new profile") do
            play new_profile(@new_name.text)
          end

          new_name = File.basename File.expand_path("~")
          new_name = "Player" if new_name.empty?
          @new_name.text = new_name
        end
      end
    end

    def play(profile)
      @game.instance_variable_set :@profile, profile
      push_game_state Play.new(@game)
    end

    def new_profile(name)
      new_profile = RubyWarrior::Profile.new
      new_profile.tower_path = @game.towers[0].path
      new_profile.warrior_name = name
      new_profile
    end
  end
end