module RubyWarrior
  module Abilities
    class Rest < Base
      alias_method :original_perform, :perform
      def perform
        original = @unit.health
        original_perform
        $window.current_game_state.unit_health_changed(@unit, @unit.health - original) if @unit.health > original
      end
    end
  end
end
