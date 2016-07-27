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
    class ItemCollection
      include Enumerable

      def initialize(search_method, search_params, model, client)
        @search_method = search_method
        @search_params = search_params
        @model = model
        @client = client
      end

      def each(&block)
        return enum_for(:each) unless block_given?
        items.each_page do |page|
          items_array = _build_items_from_response(page.items, @model)
          items_array.each do |item|
            yield item
          end
        end
      end

      def empty?
        items.empty?
      end

      private
      def _build_items_from_response(items, model)
        ret = []
        items.each do |item|
          record = model.new
          data = record.instance_variable_get("@data")
          model.attributes.attributes.each do |name, attr|
            data.set_attribute(name, attr.extract(item))
          end
          data.clean!
          ret << record
        end
        ret
      end

      def items
        @_items ||= @client.send(@search_method, @search_params)
      end

    end
  end
end
