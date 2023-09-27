# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class MapMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil, ''
            nil
          when Hash
            raw_value
          else
            if raw_value.respond_to?(:to_h)
              raw_value.to_h
            else
              msg = "Don't know how to make #{raw_value} of type " \
                    "#{raw_value.class} into a hash!"
              raise ArgumentError, msg
            end
          end
        end

        def serialize(raw_value)
          map = type_cast(raw_value)
          if map.is_a?(Hash)
            map
          elsif map.nil?
            nil
          else
            msg = "expected a Hash value or nil, got #{map.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
