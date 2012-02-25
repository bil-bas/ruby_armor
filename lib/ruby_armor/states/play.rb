module RubyArmor
  class Play < Fidgit::GuiState
    FLOOR_COLOR = Color.rgba(255, 255, 255, 125)

    TILE_WIDTH, TILE_HEIGHT = 8, 12
    SPRITE_WIDTH, SPRITE_HEIGHT = 8, 8
    SPRITE_OFFSET_X, SPRITE_OFFSET_Y = 64, 64
    SPRITE_SCALE = 5

    ENEMY_TYPES = [
        RubyWarrior::Units::Wizard,
        RubyWarrior::Units::ThickSludge,
        RubyWarrior::Units::Sludge,
        RubyWarrior::Units::Archer,
    ]
    WARRIOR_TYPES = [
        RubyWarrior::Units::Warrior,
        RubyWarrior::Units::Golem,
    ]
    FRIEND_TYPES = [
        RubyWarrior::Units::Captive,
    ]

    trait :timer

    def initialize(game)
      @game = game
      super()
    end

    def setup
      super

      RubyWarrior::UI.proxy = self

      @tiles = SpriteSheet.new "tiles.png", TILE_WIDTH, TILE_HEIGHT, 8
      @sprites = SpriteSheet.new "characters.png", SPRITE_WIDTH, SPRITE_HEIGHT, 4
      @max_turns = 100 # Just to recognise a stalemate ;)

      vertical spacing: 0, padding: 10 do
        horizontal padding: 0, height: $window.height * 0.5, width: 780 do
          # Space for the game graphics.
          vertical padding: 0, height: $window.height * 0.5, align_h: :fill

          vertical padding: 0, height: $window.height * 0.5, width: 100 do
            # Labels at top-right.
            @tower_label = label "", tip: "Each tower has a different difficulty level"
            @level_label = label "Level:", tip: "Each tower contains 9 levels"
            @turn_label = label "Turn:", tip: "Current turn; starvation at #{@max_turns} to avoid endless games"
            @health_label = label "Health:", tip: "The warrior's remaining health; death occurs at 0"

            # Buttons underneath them.
            button_options = {
                :width => 70,
                :justify => :center,
                shortcut: :auto,
                shortcut_color: Color.rgb(150, 255, 0),
                border_thickness: 0,
            }
            @start_button = button "Start", button_options.merge(tip: "Start running player.rb in this level") do
              start_level
            end

            @reset_button = button "Reset", button_options.merge(tip: "Restart the level") do
              prepare_level
            end

            @hint_button = button "Hint", button_options.merge(tip: "Get hint on how best to approach the level") do
              message replace_syntax(level.tip)
            end

            @continue_button = button "Continue", button_options.merge(tip: "Climb up the stairs to the next level") do
              @game.prepare_next_level
              prepare_level
            end

            # Choose turn-duration with a slider.
            horizontal padding: 0, spacing: 0 do
              @turn_duration_label = label "", font_height: 12
              @turn_duration_slider = slider width: 55, range: 0..1000, tip: "Turn duration (ms)" do |_, value|
                @turn_duration = value * 0.001
                @turn_duration_label.text = "%4dms" % value.to_s
              end
              @turn_duration_slider.value = 500
            end
          end
        end

        # Text areas at the bottom.
        horizontal padding: 0, spacing: 10 do
          # Tabs to contain README and player code to the left.
          vertical padding: 0, spacing: 0 do
            @tabs_group = group do
              @tab_buttons = horizontal padding: 0, spacing: 4 do
                %w[README player.rb].each do |name|
                  radio_button(name.to_s, name, border_thickness: 0, tip: "View #{name}")
                end

                horizontal padding: 0, padding_left: 70 do
                  # Default editor for Windows.
                  ENV['EDITOR'] = "notepad" if Gem.win_platform? and ENV['EDITOR'].nil?

                  tip = ENV['EDITOR'] ? "Edit file in #{ENV['EDITOR']} (set ENV['EDITOR'] to use a different editor)" : "ENV['EDITOR'] not set"
                  button "edit", tip: tip, enabled: ENV['EDITOR'], font_height: 12, border_thickness: 0 do
                    command = %<"#{ENV['EDITOR']}" "#{File.join(level.player_path, @tabs_group.value)}">
                    $stdout.puts "SYSTEM: #{command}"
                    Thread.new { system command }
                  end
                end
              end

              subscribe :changed do |_, value|
                current = @tab_buttons.find {|elem| elem.value == value }
                @tab_buttons.each {|t| t.enabled = (t != current) }
                current.color, current.background_color = current.background_color, current.color

                @tab_contents.clear
                @tab_contents.add @tab_windows[value]
              end
            end

            # Contents of those tabs.
            @tab_contents = vertical padding: 0, width: 380, spacing: 10, height: $window.height * 0.45

            create_tab_windows
            @tabs_group.value = "README"
          end

          # Log on the right
          vertical padding: 0, width: 380, height: 278 do
            @log_window = scroll_window width: 380, height: 278 do
              @log_display = text_area width: 368, editable: false
            end
            @log_window.background_color = @log_display.background_color
          end
        end
      end

      prepare_level
    end

    def create_tab_windows
      @tab_windows = {}
      @tab_windows["README"] = Fidgit::ScrollWindow.new width: 380, height: 250 do
        @readme_display = text_area width: 368, editable: false
      end
      @tab_windows["README"].background_color = @readme_display.background_color

      @tab_windows["player.rb"] = Fidgit::ScrollWindow.new width: 380, height: 250 do
        @code_display = text_area width: 368, editable: false
      end
      @tab_windows["player.rb"].background_color = @code_display.background_color
    end

    def prepare_level
      @log_display.text = ""
      @continue_button.enabled = false
      @hint_button.enabled = false
      @reset_button.enabled = false
      @start_button.enabled = true

      @exception = nil

      @game.prepare_next_level unless profile.current_level.number > 0

      # Continually poll the player code file to see when it is edited.
      stop_timer :refresh_code
      friendly_line_endings = false
      every(100, :name => :refresh_code) do
        begin
          player_file = File.join level.player_path, "player.rb"
          player_code = File.read player_file
          stripped_code = player_code.strip
          @loaded_code ||= ""
          unless @loaded_code == stripped_code
            $stdout.puts "Detected change in player.rb"

            # Rewrite file as Windows text file if it is the default (a unix file).
            # If the file loaded in binary == the code loaded as text, then the file
            # must have Unix endings (\n => same as a text file in memory) rather than
            # Windows endings (\r\n => different than text file in memory).
            if !friendly_line_endings and Gem.win_platform? and
                (File.open(player_file, "rb", &:read).strip == stripped_code)

              File.open(player_file, "w") {|f| f.puts player_code }
              $stdout.puts "Converted to Windows line endings: #{player_file}"
            end
            friendly_line_endings = true # Either will have or don't need to.

            @code_display.text = stripped_code
            @loaded_code = stripped_code
            prepare_level
          end
        rescue Errno::ENOENT
          # This can happen if the file is busy.
        end
      end

      @level = profile.current_level # Need to store this because it gets forgotten by the profile/game :(
      @turn = 0
      @playing = false
      level.load_level

      @readme_display.text = replace_syntax File.read(File.join(level.player_path, "README"))

      print "#{profile.warrior_name} climbs up to level #{level.number}\n"
      @tile_set = %w[beginner intermediate].index(profile.tower.name) || 2 # We don't know what the last tower will be called.

      warrior = floor.units.find {|u| u.is_a? RubyWarrior::Units::Warrior }
      @entry_x, @entry_y = warrior.position.x, warrior.position.y

      refresh_labels

      # Load the player's own code, which might explode!
      begin
        level.load_player
      rescue SyntaxError, StandardError => ex
        handle_exception ex
        return
      end
    end

    def refresh_labels
      @tower_label.text =  profile.tower.name.capitalize
      @level_label.text =  "Level:   #{level.number}"
      @turn_label.text =   "Turn:   #{(@turn + 1).to_s.rjust(2)}"
      @health_label.text = "Health: #{level.warrior.health.to_s.rjust(2)}"
    end

    def start_level
      @reset_button.enabled = true
      @start_button.enabled = false
      @playing = true
      @take_next_turn_at = Time.now + @turn_duration
      refresh_labels
    end

    def replace_syntax(string)
      # Used in readme.
      string.gsub!(/warrior\.[^! \n]+./) do |s|
        if s[-1, 1] == '!'
          "<c=eeee00>#{s}</c>" # Commands.
        else
          "<c=00ff00>#{s}</c>" # Queries.
        end
      end

      replace_log string
    end

    def replace_log(string)
      @enemy_pattern ||= /([asw])/i #Archer, sludge, thick sludge, wizard.
      @friend_pattern ||= /([C])/
      @warrior_pattern ||= /([@G])/ # Player and golem

      # Used in log.
      string.gsub(/\|(.*)\|/i) {|c|
                c.gsub(@enemy_pattern, '<c=ff0000>\1</c>')
                 .gsub(@friend_pattern, '<c=00dd00>\1</c>')
                 .gsub(@warrior_pattern, '<c=aaaaff>\1</c>')
             }
            .gsub(/^(#{profile.warrior_name}.*)/, '<c=aaaaff>\1</c>')   # Player doing stuff.
            .gsub(/(\-{3,}| \| )/, '<c=777777>\1</c>')                  # Walls.
    end

    def profile; @game.profile; end
    def level; @level; end
    def floor; level.floor; end

    def play_turn
      self.puts "- turn #{@turn+1} -"
      self.print floor.character

      begin
        floor.units.each(&:prepare_turn)
        floor.units.each(&:perform_turn)
      rescue => ex
        handle_exception ex
        return
      end

      @turn += 1
      level.time_bonus -= 1 if level.time_bonus > 0

      @take_next_turn_at = Time.now + @turn_duration

      refresh_labels

      if level.passed?
        if @game.next_level.exists?
          @continue_button.enabled = true
          self.puts "Success! You have found the stairs."
        else
          self.puts "CONGRATULATIONS! You have climbed to the top of the tower and rescued the fair maiden Ruby."
        end
        level.tally_points
      elsif level.failed?
        @hint_button.enabled = true
        self.puts "Sorry, you failed level #{level.number}. Change your script and try again."
      elsif out_of_time?
        @hint_button.enabled = true
        self.puts "Sorry, you starved to death on level #{level.number}. Change your script and try again."
      end
    end

    def handle_exception(exception)
      return if @exception and exception.message == @exception.message

      self.puts "\n#{profile.warrior_name} was eaten by a #{exception.class}!\n"
      self.puts exception.message
      self.puts
      self.puts exception.backtrace.join("\n")

      # TODO: Make this work without it raising exceptions in Fidgit :(
      #exception.message =~ /:(\d+):/
      #exception_line = $1.to_i - 1
      #code_lines = @code_display.text.split "\n"
      #code_lines[exception_line] = "<c=ff0000>{code_lines[exception_line]}</c>"
      #@code_display.text = code_lines.join "\n"

      @start_button.enabled = false

      @exception = exception
    end

    def out_of_time?
      @turn > @max_turns
    end

    def puts(message = "")
      print "#{message}\n"
    end

    def print(message)
      #$stdout.puts message
      @log_display.text += replace_log message
      @log_window.offset_y = Float::INFINITY
    end

    def draw
      super

      $window.translate SPRITE_OFFSET_X, SPRITE_OFFSET_Y do
        $window.scale SPRITE_SCALE do
          # Draw horizontal walls.
          floor.width.times do |x|
            light = x % 2
            light = 2 if light == 1 and (Gosu::milliseconds / 500) % 2 == 0
            @tiles[light + 3, @tile_set].draw x * SPRITE_WIDTH, -SPRITE_HEIGHT, 0
            @tiles[3, @tile_set].draw x * SPRITE_WIDTH, floor.height * SPRITE_HEIGHT, floor.height
          end
          # Draw vertical walls.
          (-1..floor.height).each do |y|
            @tiles[3, @tile_set].draw -SPRITE_WIDTH, y * SPRITE_HEIGHT, y
            @tiles[3, @tile_set].draw floor.width * SPRITE_WIDTH, y * SPRITE_HEIGHT, y
          end

          # Draw floor
          floor.width.times do |x|
            floor.height.times do |y|
              @tiles[(x + y + 1) % 2, @tile_set].draw x * SPRITE_WIDTH, y * SPRITE_HEIGHT, 0, 1, 1, FLOOR_COLOR
            end
          end

          # Draw stairs (exit)
          @tiles[2, @tile_set].draw floor.stairs_location[0] * SPRITE_WIDTH, floor.stairs_location[1] * SPRITE_HEIGHT, 0

          # Draw trapdoor (entrance)
          @tiles[6, @tile_set].draw @entry_x * SPRITE_WIDTH, @entry_y * SPRITE_HEIGHT, 0

          # Draw units.
          floor.units.each do |unit|
            sprite = case unit
                       when RubyWarrior::Units::Warrior
                         @sprites[0, 0]
                       when RubyWarrior::Units::Wizard
                         @sprites[0, 1]
                       when RubyWarrior::Units::ThickSludge
                         @sprites[2, 1]
                       when RubyWarrior::Units::Sludge
                         @sprites[1, 1]
                       when RubyWarrior::Units::Archer
                         @sprites[3, 1]
                       when RubyWarrior::Units::Captive
                         @sprites[0, 2]
                       when RubyWarrior::Units::Golem
                         @sprites[1, 2]
                       else
                         raise "unknown unit: #{unit.class}"
                     end

            sprite.draw unit.position.x * SPRITE_WIDTH, unit.position.y * SPRITE_HEIGHT, unit.position.y

            if unit.bound?
              @sprites[2, 2].draw unit.position.x * SPRITE_WIDTH, unit.position.y * SPRITE_HEIGHT, unit.position.y
            end
          end
        end
      end
    end

    def unit_health_changed(unit, amount)
      color = (amount > 0) ? Color::GREEN : Color::RED
      y_offset = (amount > 0) ? -0.15 : +0.15
      FloatingText.create "#{amount > 0 ? "+" : ""}#{amount}",
                          :color => color,
                          :x => unit.position.x * SPRITE_SCALE * SPRITE_WIDTH  + (SPRITE_SCALE * SPRITE_WIDTH / 2) + SPRITE_OFFSET_X,
                          :y => (unit.position.y + y_offset) * SPRITE_SCALE * SPRITE_HEIGHT + SPRITE_OFFSET_Y
    end

    def update
      super

      if @playing and Time.now >= @take_next_turn_at and not (level.passed? || level.failed? || out_of_time? || @exception)
        play_turn
      end
    end
  end
end