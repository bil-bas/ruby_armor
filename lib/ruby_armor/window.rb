module RubyArmor
  class Window < Chingu::Window
    def initialize
      super 800, 600, false

      Gosu::enable_undocumented_retrofication

      self.caption = "RubyArmor for RubyWarrior"
      push_game_state ChooseProfile
    end
  end
end