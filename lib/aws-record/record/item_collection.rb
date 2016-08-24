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

      # Provides an enumeration of the results of a query or scan operation on
      # your table, automatically converted into item classes.
      #
      # WARNING: This will enumerate over your entire partition in the case of
      # query, and over your entire table in the case of scan, save for key and
      # filter expressions used. This means that enumerable operations that
      # iterate over the full result set could make many network calls, or use a
      # lot of memory to build response objects. Use with caution.
      #
      # @return [Enumerable<Aws::Record>] an enumeration over the results of
      #   your query or scan request. These results are automatically converted
      #   into items on your behalf.
      def each(&block)
        return enum_for(:each) unless block_given?
        items.each_page do |page|
          items_array = _build_items_from_response(page.items, @model)
          items_array.each do |item|
            yield item
          end
        end
      end

      # Checks if the query/scan result is completely blank.
      #
      # WARNING: This can and will query your entire partition, or scan your
      # entire table, if no results are found. Especially if your table is
      # large, use this with extreme caution.
      #
      # @return [Boolean] true if the query/scan result is empty, false
      #   otherwise.
      def empty?
        items.each_page do |page|
          return false if !page.items.empty?
        end
        true
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
