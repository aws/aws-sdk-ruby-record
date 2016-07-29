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
    autoload :DirtyTracking,    'aws-record/record/dirty_tracking'
    autoload :Errors,           'aws-record/record/errors'
    autoload :ItemCollection,   'aws-record/record/item_collection'
    autoload :ItemData,         'aws-record/record/item_data'
    autoload :ItemOperations,   'aws-record/record/item_operations'
    autoload :KeyAttributes,    'aws-record/record/key_attributes'
    autoload :ModelAttributes,  'aws-record/record/model_attributes'
    autoload :Query,            'aws-record/record/query'
    autoload :SecondaryIndexes, 'aws-record/record/secondary_indexes'
    autoload :TableMigration,   'aws-record/record/table_migration'
    autoload :VERSION,          'aws-record/record/version'

    module Marshalers
      autoload :StringMarshaler,     'aws-record/record/marshalers/string_marshaler'
      autoload :BooleanMarshaler,    'aws-record/record/marshalers/boolean_marshaler'
      autoload :IntegerMarshaler,    'aws-record/record/marshalers/integer_marshaler'
      autoload :FloatMarshaler,      'aws-record/record/marshalers/float_marshaler'
      autoload :DateMarshaler,       'aws-record/record/marshalers/date_marshaler'
      autoload :DateTimeMarshaler,   'aws-record/record/marshalers/date_time_marshaler'
      autoload :ListMarshaler,       'aws-record/record/marshalers/list_marshaler'
      autoload :MapMarshaler,        'aws-record/record/marshalers/map_marshaler'
      autoload :StringSetMarshaler,  'aws-record/record/marshalers/string_set_marshaler'
      autoload :NumericSetMarshaler, 'aws-record/record/marshalers/numeric_set_marshaler'
    end

  end
end
