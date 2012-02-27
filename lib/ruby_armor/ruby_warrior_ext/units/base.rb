module RubyWarrior
  module Units
    class Base
      alias_method :original_take_damage, :take_damage
      def take_damage(amount)
        state = $window.game_state_manager.inside_state || $window.current_game_state
        state.unit_health_changed self, -amount
        original_take_damage amount
      end
    end
  end
end