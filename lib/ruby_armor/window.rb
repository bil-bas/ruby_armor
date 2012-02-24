module RubyArmor
  class Window < Chingu::Window
    def initialize
      super 800, 600, false

      Gosu::enable_undocumented_retrofication

      self.caption = "RubyArmour GUI for RubyWarrior"
      push_game_state Play
    end
  end
end