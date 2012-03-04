module RubyArmor
  class Play < Fidgit::GuiState
    FLOOR_COLOR = Color.rgba(255, 255, 255, 125)

    TILE_WIDTH, TILE_HEIGHT = 8, 12
    SPRITE_WIDTH, SPRITE_HEIGHT = 8, 8
    SPRITE_SCALE = 5

    MAX_TURN_DELAY = 1
    MIN_TURN_DELAY = 0
    TURN_DELAY_STEP = 0.1

    MAX_TURNS = 100

    SHORTCUT_COLOR = Color.rgb(175, 255, 100)

    FILE_SYNC_DELAY = 0.5 # 2 polls per second.

    # Sprites to show based on player facing.
    FACINGS = {
        :east => 0,
        :south => 1,
        :west => 2,
        :north => 3,
    }

    # Rows in the warriors.png to use for each warrior type.
    WARRIORS = {
        :valkyrie => 0,
        :mercenary => 1,
        :monk => 2,
        :burglar => 3,
    }

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

    attr_reader :turn
    def turn=(turn)
      @turn = turn
      @take_next_turn_at = Time.now + @config.turn_delay
      @log_contents["current turn"].text = replace_log @turn_logs[turn]

      turn
    end

    def initialize(game, config)
      @game, @config = game, config
      super()
    end

    def setup
      super

      RubyWarrior::UI.proxy = self

      @tiles = SpriteSheet.new "tiles.png", TILE_WIDTH, TILE_HEIGHT, 8
      @warrior_sprites = SpriteSheet.new "warriors.png", SPRITE_WIDTH, SPRITE_HEIGHT, 4
      @mob_sprites = SpriteSheet.new "mobs.png", SPRITE_WIDTH, SPRITE_HEIGHT, 4

      on_input(:escape) { pop_game_state }

      on_input(:right_arrow) do
        if !focus and @turn_slider.enabled? and @turn_slider.value < turn
          @turn_slider.value += 1
        end
      end
      on_input(:left_arrow) do
        if !focus and @turn_slider.enabled? and @turn_slider.value > 0
          @turn_slider.value -= 1
        end
      end

      vertical spacing: 10, padding: 10 do
        horizontal padding: 0, height: 260, width: 780, spacing: 10 do
          # Space for the game graphics.
          @game_window = vertical padding: 0, width: 670, height: 260

          create_ui_bar
        end

        @turn_slider = slider width: 774, range: 0..MAX_TURNS, value: 0, enabled: false, tip: "Turn" do |_, turn|
          @log_contents["current turn"].text = replace_log @turn_logs[turn]
          refresh_labels
        end

        # Text areas at the bottom.
        horizontal padding: 0, spacing: 10 do
          create_file_tabs
          create_log_tabs
        end
      end

      # Return to normal mode if extra levels have been added.
      if profile.epic?
        if profile.level_after_epic?
          # TODO: do something with log.
          log = record_log do
            @game.go_back_to_normal_mode
          end
        else
          # TODO: do something with log.
          log = record_log do
            @game.play_epic_mode
          end
        end
      end

      prepare_level
    end

    def create_ui_bar
      vertical padding: 0, height: 260, width: 100, spacing: 6 do
        # Labels at top-right.
        @tower_label = label "", tip: "Each tower has a different difficulty level"
        @level_label = label "Level:"
        @turn_label = label "Turn:", tip: "Current turn; starvation at #{MAX_TURNS} to avoid endless games"
        @health_label = label "Health:", tip: "The warrior's remaining health; death occurs at 0"

        # Buttons underneath them.
        button_options = {
            :width => 70,
            :justify => :center,
            shortcut: :auto,
            shortcut_color: SHORTCUT_COLOR,
            border_thickness: 0,
        }
        @start_button = button "Start", button_options.merge(tip: "Start running player.rb in this level") do
          start_level
        end

        @reset_button = button "Reset", button_options.merge(tip: "Restart the level") do
          profile.level_number = 0 if profile.epic?
          prepare_level
        end

        @hint_button = button "Hint", button_options.merge(tip: "Get hint on how best to approach the level") do
          message replace_syntax(level.tip)
        end

        @continue_button = button "Continue", button_options.merge(tip: "Climb up the stairs to the next level") do
          save_player_code

          # Move to next level.
          if @game.next_level.exists?
            @game.prepare_next_level
          else
            @game.prepare_epic_mode
          end

          prepare_level
        end

        horizontal padding: 0, spacing: 21 do
          options = { padding: 4, border_thickness: 0, shortcut: :auto, shortcut_color: SHORTCUT_COLOR }
          @turn_slower_button = button "-", options.merge(tip: "Make turns run slower") do
            @config.turn_delay = [@config.turn_delay + TURN_DELAY_STEP, MAX_TURN_DELAY].min if @config.turn_delay < MAX_TURN_DELAY
            update_turn_delay
          end

          @turn_duration_label = label "", align: :center

          @turn_faster_button = button "+", options.merge(tip: "Make turns run faster") do
            @config.turn_delay = [@config.turn_delay - TURN_DELAY_STEP, MIN_TURN_DELAY].max if @config.turn_delay > MIN_TURN_DELAY
            update_turn_delay
          end

          update_turn_delay
        end

        # Review old level code.
        @review_button = button "Review", button_options.merge(tip: "Review code used for each level",
                                enabled: false, border_thickness: 0, shortcut: :v) do
          ReviewCode.new(profile).show
        end
      end
    end

    def save_player_code
      # Save the code used to complete the level for posterity.
      File.open File.join(profile.player_path, "ruby_armor/player_#{profile.epic? ? "EPIC" : level.number.to_s.rjust(3, '0')}.rb"), "w" do |file|
        file.puts @loaded_code

        file.puts
        file.puts
        file.puts "#" * 40
        file.puts "=begin"
        file.puts
        file.puts record_log { level.tally_points }
        file.puts

        if profile.epic? and @game.final_report
          file.puts @game.final_report
        else
          file.puts "Completed in #{turn} turns."
        end

        file.puts
        file.puts "=end"
        file.puts "#" * 40
      end
    end

    def create_log_tabs
      vertical padding: 0, spacing: 0 do
        @log_tabs_group = group do
          @log_tab_buttons = horizontal padding: 0, spacing: 4 do
            ["current turn", "full log"].each do |name|
              radio_button(name.capitalize, name, border_thickness: 0, tip: "View #{name}")
            end

            horizontal padding_left: 50, padding: 0 do
              button "copy", tip: "Copy displayed log to clipboard", font_height: 12, border_thickness: 0, padding: 4 do
                Clipboard.copy @log_contents[@log_tabs_group.value].stripped_text
              end
            end
          end

          subscribe :changed do |_, value|
            current = @log_tab_buttons.find {|elem| elem.value == value }
            @log_tab_buttons.each {|t| t.enabled = (t != current) }
            current.color, current.background_color = current.background_color, current.color

            @log_tab_contents.clear
            @log_tab_contents.add @log_tab_windows[value]
          end
        end

        # Contents of those tabs.
        @log_tab_contents = vertical padding: 0, width: 380, height: $window.height * 0.5

        create_log_tab_windows
        @log_tabs_group.value = "current turn"
      end
    end


    def create_file_tabs
      # Tabs to contain README and player code to the left.
      vertical padding: 0, spacing: 0 do
        @file_tabs_group = group do
          @file_tab_buttons = horizontal padding: 0, spacing: 4 do
            %w[README player.rb].each do |name|
              radio_button(name.to_s, name, border_thickness: 0, tip: "View #{File.join profile.player_path, name}")
            end

            horizontal padding_left: 50, padding: 0 do
              button "copy", tip: "Copy displayed file to clipboard", font_height: 12, border_thickness: 0, padding: 4 do
                Clipboard.copy @file_contents[@file_tabs_group.value].stripped_text
              end

              # Default editor for Windows.
              ENV['EDITOR'] = "notepad" if Gem.win_platform? and ENV['EDITOR'].nil?

              tip = ENV['EDITOR'] ? "Edit file in #{ENV['EDITOR']} (set EDITOR environment variable to use a different editor)" : "ENV['EDITOR'] not set"
              button "edit", tip: tip, enabled: ENV['EDITOR'], font_height: 12, border_thickness: 0, padding: 4 do
                command = %<#{ENV['EDITOR']} "#{File.join(level.player_path, @file_tabs_group.value)}">
                $stdout.puts "SYSTEM: #{command}"
                Thread.new { system command }
              end
            end
          end

          subscribe :changed do |_, value|
            current = @file_tab_buttons.find {|elem| elem.value == value }
            @file_tab_buttons.each {|t| t.enabled = (t != current) }
            current.color, current.background_color = current.background_color, current.color

            @file_tab_contents.clear
            @file_tab_contents.add @file_tab_windows[value]
          end
        end

        # Contents of those tabs.
        @file_tab_contents = vertical padding: 0, width: 380, height: $window.height * 0.5

        create_file_tab_windows
        @file_tabs_group.value = "README"
      end
    end

    def update_turn_delay
      @turn_duration_label.text = "%2d" % [(MAX_TURN_DELAY / TURN_DELAY_STEP) + 1 - (@config.turn_delay / TURN_DELAY_STEP)]
      @turn_slower_button.enabled = @config.turn_delay < MAX_TURN_DELAY
      @turn_faster_button.enabled = @config.turn_delay > MIN_TURN_DELAY
      @turn_duration_label.tip = "Speed of turns (high is faster; currently turns take #{(@config.turn_delay * 1000).to_i}ms)"
    end

    def create_log_tab_windows
      @log_tab_windows = {}
      @log_contents = {}
      ["current turn", "full log"].each do |log|
        @log_tab_windows[log] = Fidgit::ScrollWindow.new width: 380, height: 250 do
          @log_contents[log] = text_area width: 368, editable: false
        end
      end
    end

    def create_file_tab_windows
      @file_tab_windows = {}
      @file_contents = {}
      ["README", "player.rb"].each do |file|
        @file_tab_windows[file] = Fidgit::ScrollWindow.new width: 380, height: 250 do
          @file_contents[file] = text_area width: 368, editable: false
        end
      end
    end

    def prepare_level
      @recorded_log = nil # Not initially logging.

      @log_contents["full log"].text = "" #unless profile.epic? # TODO: Might need to avoid this, since it could get REALLY long.
      @continue_button.enabled = false
      @hint_button.enabled = false
      @reset_button.enabled = false
      @start_button.enabled = true

      @exception = nil

      if profile.current_level.number.zero?
        if profile.epic?
          @game.prepare_epic_mode
          profile.level_number += 1
          profile.current_epic_score = 0
          profile.current_epic_grades = {}
        else
          @game.prepare_next_level 
        end
      end

      create_sync_timer

      @level = profile.current_level # Need to store this because it gets forgotten by the profile/game :(
      @playing = false
      level.load_level

      # List of log entries, unit drawings and health made in each turn.
      @turn_logs = Hash.new {|h, k| h[k] = "" }
      @units_record = Array.new
      @health = [level.warrior.health]

      @review_button.enabled = ReviewCode.saved_levels? profile # Can't review code unless some has been saved.

      self.turn = 0

      generate_readme

      # Initial log entry.
      self.puts "- turn   0 -"
      self.print "#{profile.warrior_name} climbs up to level #{level.number}\n"
      @log_contents["full log"].text += @log_contents["current turn"].text

      @tile_set = %w[beginner intermediate].index(profile.tower.name) || 2 # We don't know what the last tower will be called.

      warrior = floor.units.find {|u| u.is_a? RubyWarrior::Units::Warrior }
      @entry_x, @entry_y = warrior.position.x, warrior.position.y

      # Reset the time-line slider.
      @turn_slider.enabled = false
      @turn_slider.value = 0

      refresh_labels

      # Work out how to offset the level graphics based on how large it is (should be centered in the level area.
      level_width = floor.width * SPRITE_SCALE * SPRITE_WIDTH
      level_height = floor.height * SPRITE_SCALE * SPRITE_HEIGHT
      @level_offset_x = (@game_window.width - level_width) / 2
      @level_offset_y =  (@game_window.height - level_height) / 2

      # Load the player's own code, which might explode!
      begin
        level.load_player
      rescue SyntaxError, StandardError => ex
        handle_exception ex
        return
      end
    end

    def generate_readme
      readme = <<END
#{level.description}

Tip: #{level.tip}

Warrior Abilities:
END
      level.warrior.abilities.each do |name, ability|
        readme << "  warrior.#{name}\n"
        readme << "    #{ability.description}\n\n"
      end

      @file_contents["README"].text = replace_syntax readme
    end

    # Continually poll the player code file to see when it is edited.
    def create_sync_timer
      stop_timer :refresh_code

      every(FILE_SYNC_DELAY * 1000, :name => :refresh_code) do
        sync_player_file
      end
    end

    def sync_player_file
      begin
        player_file = File.join level.player_path, "player.rb"
        player_code = File.read player_file
        stripped_code = player_code.strip
        @loaded_code ||= ""
        unless @loaded_code == stripped_code
          $stdout.puts "Detected change in player.rb"

          @file_contents["player.rb"].text = stripped_code
          @loaded_code = stripped_code
          prepare_level
        end
      rescue Errno::ENOENT
        # This can happen if the file is busy.
      end
    end

    def effective_turn
      @turn_slider.enabled? ? @turn_slider.value : @turn
    end

    def refresh_labels
      @tower_label.text =  profile.tower.name.capitalize
      @level_label.text =  "Level:  #{profile.epic? ? "E" : " "}#{level.number}"
      @level_label.tip = profile.epic? ? "Playing in EPIC mode" : "Playing in normal mode"
      @turn_label.text =   "Turn:   #{effective_turn.to_s.rjust(2)}"
      @health_label.text = "Health: #{@health[effective_turn].to_s.rjust(2)}"
    end

    def start_level
      @reset_button.enabled = true
      @start_button.enabled = false
      @playing = true
      self.turn = 0
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
      string.gsub(/\|.*\|/i) {|c|
                 c = c.gsub @enemy_pattern, '<c=ff0000>\1</c>'
                 c.gsub! @friend_pattern, '<c=00dd00>\1</c>'
                 c.gsub! @warrior_pattern, '<c=aaaaff>\1</c>'
                 c.gsub '|', '<c=777777>|</c>'
             }
            .gsub(/^(#{profile.warrior_name}.*)/, '<c=aaaaff>\1</c>')   # Player doing stuff.
            .gsub(/(\-{3,})/, '<c=777777>\1</c>')                  # Walls.
    end

    def profile; @game.profile; end
    def level; @level; end
    def floor; level.floor; end

    def recording_log?; not @recorded_log.nil?; end
    def record_log
      raise "block required" unless block_given?
      @recorded_log = ""
      record = ""
      begin
        yield
      ensure
        record = @recorded_log
        @recorded_log = nil
      end
      record
    end

    def play_turn
      self.turn += 1
      self.puts "- turn #{turn.to_s.rjust(3)} -"

      begin
        actions = record_log do
          floor.units.each(&:prepare_turn)
          floor.units.each(&:perform_turn)
        end

        self.print actions
      rescue => ex
        handle_exception ex
        return
      end

      @health[turn] = level.warrior.health # Record health for later playback.

      level.time_bonus -= 1 if level.time_bonus > 0

      refresh_labels

      if level.passed?
        stop_timer :refresh_code # Don't sync after successful completion, unless reset.
        @reset_button.enabled = false if profile.epic? # Continue will save performance; reset won't.
        @continue_button.enabled = true

        if profile.next_level.exists?
          self.puts "Success! You have found the stairs."
          level.tally_points

          if profile.epic?
            # Start the next level immediately.
            self.puts "\n#{"-" * 25}\n"

            # Rush onto the next level immediately!
            profile.level_number += 1
            prepare_level
            start_level
          end
        else
          self.puts "CONGRATULATIONS! You have climbed to the top of the tower and rescued the fair maiden Ruby."
          level.tally_points

          if profile.epic?
            self.puts @game.final_report if @game.final_report
            profile.save
          end
        end

        level_ended

      elsif level.failed?
        level_ended
        self.puts "Sorry, you failed level #{level.number}. Change your script and try again."

      elsif out_of_time?
        level_ended
        self.puts "Sorry, you starved to death on level #{level.number}. Change your script and try again."

      end

      # Add the full turn's text into the main log at once, to save on re-calculations.
      @log_contents["full log"].text += @log_contents["current turn"].text
      @log_tab_windows["full log"].offset_y = Float::INFINITY

      self.puts
    end

    # Not necessarily complete; just finished.
    def level_ended
      return if profile.epic?

      @hint_button.enabled = true
      @turn_slider.enabled = true
      @turn_slider.instance_variable_set :@range, 0..turn
      @turn_slider.value = turn
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
      #code_lines = @file_contents["player.rb"].text.split "\n"
      #code_lines[exception_line] = "<c=ff0000>{code_lines[exception_line]}</c>"
      #@file_contents["player.rb"].text = code_lines.join "\n"

      @start_button.enabled = false

      @exception = exception
    end

    def out_of_time?
      turn >= MAX_TURNS
    end

    def puts(message = "")
      print "#{message}\n"
    end

    def print(message)
      if recording_log?
        @recorded_log << message
      else
        @turn_logs[turn] << message
        @log_contents["current turn"].text = replace_log @turn_logs[turn]
      end
    end

    def draw
      super

      $window.translate @level_offset_x, @level_offset_y do
        $window.scale SPRITE_SCALE do
          draw_map

          # Draw stairs (exit)
          if floor.stairs_location[0] == 0
            # flip when on the left hand side.
            @tiles[2, @tile_set].draw (floor.stairs_location[0] + 1) * SPRITE_WIDTH, floor.stairs_location[1] * SPRITE_HEIGHT, 0, -1
          else
            @tiles[2, @tile_set].draw floor.stairs_location[0] * SPRITE_WIDTH, floor.stairs_location[1] * SPRITE_HEIGHT, 0
          end

          # Draw trapdoor (entrance)
          @tiles[6, @tile_set].draw @entry_x * SPRITE_WIDTH, @entry_y * SPRITE_HEIGHT, 0

          draw_units
        end
      end
    end

    def draw_map
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
    end

    def draw_units
      @units_record[effective_turn] ||= $window.record 1, 1 do
        floor.units.sort_by {|u| u.position.y }.each do |unit|
          sprite = case unit
                     when RubyWarrior::Units::Warrior
                       @warrior_sprites[FACINGS[unit.position.direction], WARRIORS[@config.warrior_class]]
                     when RubyWarrior::Units::Wizard
                       @mob_sprites[0, 1]
                     when RubyWarrior::Units::ThickSludge
                       @mob_sprites[2, 1]
                     when RubyWarrior::Units::Sludge
                       @mob_sprites[1, 1]
                     when RubyWarrior::Units::Archer
                       @mob_sprites[3, 1]
                     when RubyWarrior::Units::Captive
                       @mob_sprites[0, 2]
                     when RubyWarrior::Units::Golem
                       @mob_sprites[1, 2]
                     else
                       raise "unknown unit: #{unit.class}"
                   end

          # Draw unit itself
          x, y, z_order = unit.position.x * SPRITE_WIDTH, unit.position.y * SPRITE_HEIGHT, unit.position.y
          sprite.draw x, y, z_order

          # Draw health number
          $window.scale 0.25 do
            Font[12].draw unit.health, x * 4, y * 4 - 20, z_order
          end

          # Draw health-bar (black border, with red bar).
          draw_rect x, y - 2, SPRITE_WIDTH, 1, z_order, Color::BLACK
          draw_rect x + HEALTH_BAR_BORDER, y + HEALTH_BAR_BORDER - 2,
                    (SPRITE_WIDTH - 1) * unit.health / unit.max_health + HEALTH_BAR_BORDER * 2, 1 - HEALTH_BAR_BORDER * 2,
                    z_order, Color::RED

          # Draw binding rope if if it tied up.
          if unit.bound?
            @mob_sprites[2, 2].draw x, y, z_order
          end
        end
      end

      @units_record[effective_turn].draw 0, 0, 0
    end

    HEALTH_BAR_BORDER = 0.25

    def unit_health_changed(unit, amount)
      return unless @level_offset_x # Ignore changes out of order, such as between epic levels.

      color = (amount > 0) ? Color::GREEN : Color::RED
      y_offset = (amount > 0) ? -0.15 : +0.15
      FloatingText.create "#{amount > 0 ? "+" : ""}#{amount}",
                          :color => color,
                          :x => unit.position.x * SPRITE_SCALE * SPRITE_WIDTH  + (SPRITE_SCALE * SPRITE_WIDTH / 2) + @level_offset_x,
                          :y => (unit.position.y + y_offset) * SPRITE_SCALE * SPRITE_HEIGHT + @level_offset_y
    end

    def update
      super

      if @playing and Time.now >= @take_next_turn_at and not (level.passed? || level.failed? || out_of_time? || @exception)
        play_turn
      end
    end
  end
end