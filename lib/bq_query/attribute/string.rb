module BqQuery
  module Attribute
    class String < Base
      def parse
        @value
      end
    end
  end
end
