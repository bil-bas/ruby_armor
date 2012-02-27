module RubyWarrior
  module Abilities
    class Rest < Base
      alias_method :original_perform, :perform
      def perform
        original = @unit.health
        original_perform
        state = $window.game_state_manager.inside_state || $window.current_game_state
        state.unit_health_changed(@unit, @unit.health - original) if @unit.health > original
      end
    end
  end
end
