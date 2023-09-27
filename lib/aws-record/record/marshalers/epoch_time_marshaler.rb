# frozen_string_literal: true

require 'time'

module Aws
  module Record
    module Marshalers
      class EpochTimeMarshaler
        def initialize(opts = {})
          @use_local_time = opts[:use_local_time] ? true : false
        end

        def type_cast(raw_value)
          value = _format(raw_value)
          if !@use_local_time && value.is_a?(::Time)
            value.utc
          else
            value
          end
        end

        def serialize(raw_value)
          time = type_cast(raw_value)
          if time.nil?
            nil
          elsif time.is_a?(::Time)
            time.to_i
          else
            msg = "expected a Time value or nil, got #{time.class}"
            raise ArgumentError, msg
          end
        end

        private

        def _format(raw_value)
          case raw_value
          when nil, ''
            nil
          when ::Time
            raw_value
          when Integer, BigDecimal # timestamp
            ::Time.at(raw_value)
          else # Date, DateTime, or String
            ::Time.parse(raw_value.to_s)
          end
        end
      end
    end
  end
end
