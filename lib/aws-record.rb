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

require 'aws-sdk-resources'

module Aws
  autoload :Record, 'aws-record/record'

  module Record
    autoload :Attribute,        'aws-record/record/attribute'
    autoload :Attributes,       'aws-record/record/attributes'
    autoload :Errors,           'aws-record/record/errors'
    autoload :ItemCollection,   'aws-record/record/item_collection'
    autoload :ItemOperations,   'aws-record/record/item_operations'
    autoload :Query,            'aws-record/record/query'
    autoload :SecondaryIndexes, 'aws-record/record/secondary_indexes'
    autoload :TableMigration,   'aws-record/record/table_migration'
    autoload :VERSION,          'aws-record/record/version'

    module Attributes
      autoload :StringMarshaler,   'aws-record/record/attributes/string_marshaler'
      autoload :BooleanMarshaler,  'aws-record/record/attributes/boolean_marshaler'
      autoload :IntegerMarshaler,  'aws-record/record/attributes/integer_marshaler'
      autoload :FloatMarshaler,    'aws-record/record/attributes/float_marshaler'
      autoload :DateMarshaler,     'aws-record/record/attributes/date_marshaler'
      autoload :DateTimeMarshaler, 'aws-record/record/attributes/date_time_marshaler'
      autoload :ListMarshaler,     'aws-record/record/attributes/list_marshaler'
    end

  end
end
