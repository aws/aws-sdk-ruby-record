require 'date'

module Aws
  module Record
    module Attributes
      module DateMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when Date
              raw_value
            when Integer
              begin
                Date.parse(Time.at(raw_value).to_s) # assumed timestamp
              rescue
                nil
              end
            else
              begin
                Date.parse(raw_value.to_s) # Time, DateTime or String
              rescue
                nil
              end
            end
          end

          def serialize(raw_value, options = {})
            date = type_cast(raw_value)
            if date.nil?
              nil
            elsif date.is_a?(Date)
              date.strftime('%Y-%m-%d')
            else
              raise ArgumentError, "expected a Date value or nil, got #{date.class}"
            end
          end

        end

      end
    end
  end
end
