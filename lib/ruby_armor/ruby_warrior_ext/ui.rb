module RubyWarrior
  class UI
    class << self
      attr_accessor :proxy

      def puts(msg)
        print msg + "\n"
      end

      def puts_with_delay(msg)
        puts msg
      end

      def print(msg)
        proxy.print msg
      end

      def gets
        ""
      end

      def request(msg)
        print msg
        true
      end

      def ask(msg)
        print msg
        true
      end

      def choose(item, options)
        response = options.first
        if response.kind_of? Array
          response.first
        else
          response
        end
      end
    end
  end


end