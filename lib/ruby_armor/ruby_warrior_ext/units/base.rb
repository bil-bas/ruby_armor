module RubyWarrior
  module Units
    class Base
      alias_method :original_take_damage, :take_damage
      def take_damage(amount)
        $window.current_game_state.unit_health_changed self, -amount
        original_take_damage(amount)
      end
    end
  end
end