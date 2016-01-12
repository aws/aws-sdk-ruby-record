# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

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
              nil
            elsif datetime.is_a?(DateTime)
              datetime.strftime('%Y-%m-%dT%H:%M:%S%Z') 
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
