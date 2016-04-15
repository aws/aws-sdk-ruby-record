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
    class Batch
      include Enumerable

      attr_reader :items

      def initialize(model, client, items = [])
        @model = model
        @client = client
        @items = items.map do |item|
          check_item_class(item)
        end
      end

      def each(&_block)
        return enum_for(:each) unless block_given?
        @items.each do |item|
          yield item
        end
      end

      def add(item)
        @items.include?(item) ? @items : @items << check_item_class(item)
      end

      def size
        @items.size
      end

      private
      def check_item_class(item)
        msg = "Expected a #{@model.class}, got a #{item.class}"
        raise ArgumentError, msg unless item.is_a?(@model)
        item
      end

    end
  end
end
