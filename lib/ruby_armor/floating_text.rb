module RubyArmor
  class FloatingText < GameObject
    FONT_SIZE = 20

    def initialize(text, options = {})
      super(options)

      @final_y = y - 60
      @text = text
      @font = Font["ProggyCleanSZ.ttf", FONT_SIZE]
    end

    def update
      self.y -= 1 # TODO: scale this with FPS.
      destroy if y < @final_y
    end

    def draw
      @font.draw_rel @text, x, y, zorder, 0.5, 0.5, 1, 1, color
    end
  end
end