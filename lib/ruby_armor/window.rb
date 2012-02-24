module RubyArmor
  class Window < Chingu::Window
    def initialize
      super 800, 600, false

      self.caption = "RubyArmour GUI for RubyWarrior"
      push_game_state Play
    end
  end
end