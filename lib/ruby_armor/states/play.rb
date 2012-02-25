module RubyArmor
  class Play < Fidgit::GuiState
    trait :timer

    def setup
      super

      RubyWarrior::UI.proxy = self

      vertical spacing: 0, padding: 10 do
        horizontal padding: 0, height: $window.height * 0.5, width: 780 do
          vertical padding: 0, height: $window.height * 0.5, align_h: :fill
          vertical padding: 0, height: $window.height * 0.5, width: 100 do
            @level_label = label "Level: 0"
            @turn_label = label "Turn: 0"
            @health_label = label "Health: 0"
            button "restart" do
              @log_display.text = ""
              start_game
            end
          end
        end
        horizontal padding: 0, spacing: 10 do
          vertical padding: 0, width: 380, spacing: 10, height: $window.height * 0.45 do
            @readme_window = scroll_window width: 380, height: $window.height * 0.23 do
              @readme_display = text_area width: 368, editable: false
            end
            @readme_window.background_color = @readme_display.background_color

            @code_window = scroll_window width: 380, height: $window.height * 0.2 do
              @code_display = text_area width: 368, editable: false
            end
            @code_window.background_color = @code_display.background_color
          end

          vertical padding: 0, width: 380, height: $window.height * 0.45 do
            @log_window = scroll_window width: 380, height: $window.height * 0.45 do
              @log_display = text_area width: 368, editable: false
            end
            @log_window.background_color = @log_display.background_color
          end
        end
      end

      start_game
    end

    def start_game
      # Create the game.
      @game = RubyWarrior::Game.new

      # Create brand new profile or use the first of those already set.
      profile_to_use = if @game.profiles.empty?
                         new_profile = RubyWarrior::Profile.new
                         new_profile.tower_path = @game.towers[0].path
                         new_profile.warrior_name = "Bob"
                         new_profile
                       else
                         @game.profiles[0]
                       end

      @game.instance_variable_set :@profile, profile_to_use

      @game.prepare_next_level unless profile.current_level.number > 0

      # Start level.
      @_level = profile.current_level
      level.load_player
      level.load_level

      @readme_display.text = File.read File.join(level.player_path, "README")
      every(100) do
        player_code = File.read File.join(level.player_path, "player.rb")
        @code_display.text = player_code unless @code_display.text == player_code
      end

      print "Starting Level #{level.number}\n"

      @turn = 0
      @turn_label.text = "Turn: 1"

      @take_next_turn_at = Time.now + 0.5
    end

    def profile; @game.profile; end
    def level; @_level; end
    def floor; level.floor; end

    def play_turn
      self.puts "- turn #{@turn+1} -"
      self.print floor.character

      floor.units.each(&:prepare_turn)
      floor.units.each(&:perform_turn)
      @turn += 1

      @level_label.text = "Level: #{level.number}"
      @turn_label.text = "Turn: #{@turn+1}"
      @health_label.text = "Health: #{level.warrior.health}"

      level.time_bonus -= 1 if level.time_bonus > 0

      @take_next_turn_at = Time.now + 0.5

      if level.passed?
        if @game.next_level.exists?
          self.puts "Success! You have found the stairs."
        else
          self.puts "CONGRATULATIONS! You have climbed to the top of the tower and rescued the fair maiden Ruby."
        end
        level.tally_points
      elsif level.failed?
        self.puts "Sorry, you failed level #{level.number}. Change your script and try again."
      end
    end

    def puts(message)
      print message + "\n"
    end

    def print(message)
      $stdout.puts message
      @log_display.text += message
      @log_window.offset_y = Float::INFINITY
    end

    def draw
      super

      $window.translate 64, 64 do
        $window.scale 48 do
          # Draw walls.
          floor.width.times do |x|
            draw_rect x, -1, 1, 1, 0, Color.rgb(100, 100, 100)
            draw_rect x, floor.height, 1, 1, 0, Color.rgb(100, 100, 100)
          end
          floor.height.times do |y|
            draw_rect -1, y, 1, 1, 0, Color.rgb(100, 100, 100)
            draw_rect floor.width, y, 1, 1, 0, Color.rgb(100, 100, 100)
          end

          # Draw stairs
          draw_rect *floor.stairs_location, 1, 1, 0, Color.rgb(0, 200, 0)

          # Draw units.
          floor.units.each do |unit|
            color = unit.is_a?(RubyWarrior::Units::Warrior) ? Color.rgb(50, 50, 255) : Color.rgb(255, 0, 0)
            draw_rect unit.position.x, unit.position.y, 1, 1, 0, color
            #[unit.character, [unit.position.x, unit.position.y], unit.health] }
          end
        end
      end
    end

    def update
      super

      if Time.now >= @take_next_turn_at and not (level.passed? || level.failed?)
        play_turn
      end
    end
  end
end