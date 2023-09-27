# frozen_string_literal: true

require 'date'

module Aws
  module Record
    module Marshalers
      class DateTimeMarshaler
        def initialize(opts = {})
          @formatter = opts[:formatter] || Iso8601Formatter
          @use_local_time = opts[:use_local_time] ? true : false
        end

        def type_cast(raw_value)
          value = _format(raw_value)
          if !@use_local_time && value.is_a?(::DateTime)
            value.new_offset(0)
          else
            value
          end
        end

        def serialize(raw_value)
          datetime = type_cast(raw_value)
          if datetime.nil?
            nil
          elsif datetime.is_a?(::DateTime)
            @formatter.format(datetime)
          else
            msg = "expected a DateTime value or nil, got #{datetime.class}"
            raise ArgumentError, msg
          end
        end

        private

        def _format(raw_value)
          case raw_value
          when nil, ''
            nil
          when ::DateTime
            raw_value
          when Integer # timestamp
            ::DateTime.parse(Time.at(raw_value).to_s)
          else # Time, Date or String
            ::DateTime.parse(raw_value.to_s)
          end
        end
      end

      module Iso8601Formatter
        def self.format(datetime)
          datetime.iso8601
        end
      end
    end
  end
end
