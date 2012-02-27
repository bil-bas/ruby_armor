module RubyArmor
  class ReviewCode < Fidgit::DialogState
    LEVELS = 1..9

    class << self
      def path_for_level(profile, level)
        File.join(profile.player_path, "ruby_armor/player_#{level.to_s.rjust(2, '0')}.rb")
      end

      # Check if there are levels saved that can be recalled.
      def saved_levels?(profile)
        LEVELS.any? {|level| File.exists? path_for_level(profile, level) }
      end
    end

    def initialize(profile)
      super(shadow_full: true)

      @profile = profile

      vertical spacing: 10, align: :center, background_color: Color::BLACK do
        label "Reviewing code that completed levels in #{profile.tower.name} tower", font_height: 20

        @tab_group = group do
          @tab_buttons = horizontal padding: 0, spacing: 4 do
            LEVELS.each do |level|
              if File.exists?(path_for_level(level))
                radio_button level.to_s, level, border_thickness: 0,
                           tip: "View code used to complete level #{level}"
              else
                button level.to_s, border_thickness: 0, enabled: false,
                       tip: "No code saved for level #{level}"
              end
            end

            horizontal padding_left: 50, padding: 0 do
              button "copy", tip: "Copy displayed code to clipboard", font_height: 12, border_thickness: 0, padding: 4 do
                Clipboard.copy @code.stripped_text
              end
            end
          end

          subscribe :changed do |_, value|
            buttons = @tab_buttons.each.grep Fidgit::RadioButton
            current = buttons.find {|b| b.value == value }
            buttons.each {|b| b.enabled = (b != current) }
            current.color, current.background_color = current.background_color, current.color

            @code.text = File.read path_for_level(value)
          end
        end

        # Contents of those tabs.
        vertical padding: 0 do
          scroll_window width: 700, height: 430 do
            @code = text_area width: 680
          end
        end

        button "Close", shortcut: :escape, align_h: :center, border_thickness: 0 do
          hide
        end

        # Pick the last level we have completed (and saved the code).
        @tab_group.value = LEVELS.to_a.reverse.find {|level| File.exists? path_for_level(level) }
      end
    end

    def path_for_level(level)
      self.class.path_for_level @profile, level
    end
  end
end