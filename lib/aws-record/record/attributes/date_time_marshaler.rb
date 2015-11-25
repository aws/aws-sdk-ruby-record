require 'date'

module Aws
  module Record
    module Attributes
      module DateTimeMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when DateTime
              raw_value
            when Integer
              begin
                DateTime.parse(Time.at(raw_value).to_s) # timestamp
              rescue
                nil
              end
            else
              begin
                DateTime.parse(raw_value.to_s) # Time, Date or String
              rescue
                nil
              end
            end
          end

          def serialize(raw_value, options = {})
            datetime = type_cast(raw_value)
            if datetime.nil?
              { null: true }
            elsif datetime.is_a?(DateTime)
              str = datetime.strftime('%Y-%m-%dT%H:%M:%S%Z') 
              { s: str }
            else
              msg = "expected a DateTime value or nil, got #{datetime.class}"
              raise ArgumentError, msg
            end
          end

        end

      end
    end
  end
end
