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

module Aws
  module Record
    module Query

      # @api private
      def self.included(sub_class)
        sub_class.extend(QueryClassMethods)
      end

      module QueryClassMethods
        def query(opts)
          query_opts = opts.merge(table_name: table_name)
          ItemCollection.new(:query, query_opts, self, dynamodb_client)
        end

        def scan(opts = {})
          scan_opts = opts.merge(table_name: table_name)
          ItemCollection.new(:scan, scan_opts, self, dynamodb_client)
        end
      end

    end
  end
end
