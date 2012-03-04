module RubyArmor
  class DungeonView < Fidgit::Vertical

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

    FLOOR_COLOR = Color.rgba 255, 255, 255, 125
    TILE_WIDTH, TILE_HEIGHT = 8, 12
    SPRITE_WIDTH, SPRITE_HEIGHT = 8, 8
    SPRITE_SCALE = 5

    attr_accessor :floor, :tile_set, :turn

    def initialize(packer, warrior_class)
      @warrior_class = warrior_class

      super padding: 0, width: 670, height: 260, parent: packer

      @tiles = SpriteSheet.new "tiles.png", TILE_WIDTH, TILE_HEIGHT, 8
      @warrior_sprites = SpriteSheet.new "warriors.png", SPRITE_WIDTH, SPRITE_HEIGHT, 4
      @mob_sprites = SpriteSheet.new "mobs.png", SPRITE_WIDTH, SPRITE_HEIGHT, 4

      @units_record = Array.new
      @turn = @tile_set = 0
    end

    def floor=(floor)
      @floor = floor

      warrior = floor.units.find {|u| u.is_a? RubyWarrior::Units::Warrior }
      @entry_x, @entry_y = warrior.position.x, warrior.position.y

      # Work out how to offset the level graphics based on how large it is (should be centered in the level area.
      level_width = floor.width * SPRITE_SCALE * SPRITE_WIDTH
      level_height = floor.height * SPRITE_SCALE * SPRITE_HEIGHT

      @level_offset_x = (width - level_width) / 2
      @level_offset_y = (height - level_height) / 2

      @tips = Hash.new

      @floor
    end

    def turn=(turn)
      @turn = turn

      # Record tips for each tile for this turn, but not if we are revisiting it.
      unless @tips[turn]
        @tips[turn] = {}
        floor.width.times do |x|
          floor.height.times do |y|
            @tips[turn][[x, y]] = tip_for_tile x, y
          end
        end
      end

      @turn
    end

    def draw
      $window.translate @level_offset_x, @level_offset_y do
        $window.scale SPRITE_SCALE do
          draw_floor
          draw_walls
          draw_stairs
          draw_entrance
          draw_units
        end
      end
    end

    # Draw trapdoor (entrance)
    def draw_entrance
      @tiles[6, @tile_set].draw @entry_x * SPRITE_WIDTH, @entry_y * SPRITE_HEIGHT, 0
    end

    # Draw stairs (exit)
    def draw_stairs
      if floor.stairs_location[0] == 0
        # flip when on the left hand side.
        @tiles[2, @tile_set].draw (floor.stairs_location[0] + 1) * SPRITE_WIDTH, floor.stairs_location[1] * SPRITE_HEIGHT, 0, -1
      else
        @tiles[2, @tile_set].draw floor.stairs_location[0] * SPRITE_WIDTH, floor.stairs_location[1] * SPRITE_HEIGHT, 0
      end
    end

    def draw_walls
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
    end

    def draw_floor
      # Draw floor
      floor.width.times do |x|
        floor.height.times do |y|
          @tiles[(x + y + 1) % 2, @tile_set].draw x * SPRITE_WIDTH, y * SPRITE_HEIGHT, 0, 1, 1, FLOOR_COLOR
        end
      end
    end

    def draw_units
      @units_record[turn] ||= $window.record 1, 1 do
        floor.units.sort_by {|u| u.position.y }.each do |unit|
          sprite = case unit
                     when RubyWarrior::Units::Warrior
                       @warrior_sprites[FACINGS[unit.position.direction], WARRIORS[@warrior_class]]
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

      @units_record[turn].draw 0, 0, 0
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

    # Tip is the unit/object under the cursor ON displayed turn.
    def tip
      # Find out the grid location of the cursor.
      cursor = $window.current_game_state.cursor
      x = (cursor.x - @level_offset_x) / (SPRITE_SCALE * SPRITE_WIDTH)
      y = (cursor.y - @level_offset_y) / (SPRITE_SCALE * SPRITE_HEIGHT)
      x, y = x.floor, y.floor

      if x == -1 or x == floor.width or y == -1 or y == floor.height
        "Wall"
      else
        @tips[@turn][[x, y]]
      end
    end

    # Tip for the tile at x, y.
    def tip_for_tile(x, y)
      # Check if the mouse is over a unit.
      unit = floor.units.find {|u| u.position.x == x and u.position.y == y }

      unit_str = if unit
                   "#{unit.to_s} (#{unit.health} / #{unit.max_health} health)"
                 else
                   nil
                 end

      unit_str += " (bound)" if unit and unit.bound?

      location_str = case [x, y]
                       when floor.stairs_location
                         "Stairs (level exit) "
                       when [@entry_x, @entry_y]
                         "Trapdoor (level entry) "
                       else
                         nil
                     end

      if unit_str and location_str
        "#{unit_str} on #{location_str}"
      elsif unit_str
        unit_str
      elsif location_str
        location_str
      else
        nil
      end
    end
  end
end