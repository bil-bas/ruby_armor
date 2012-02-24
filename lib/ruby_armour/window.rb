module RubyArmour
  class Window < Chingu::Window
    def initialize
      super 800, 600, false

      self.caption = "Rubywarrior GUI"
      push_game_state Play
    end
  end
end