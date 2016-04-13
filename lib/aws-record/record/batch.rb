module Aws
  module Record
    class Batch
      include Enumerable

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
        @items << check_item_class(item) unless @items.include?(item)
      end

      private
      def check_item_class(item)
        msg = "Expected a #{@model.class}, got a #{item.class}"
        raise ArgumentError, msg unless item.is_a?(@model.class)
        item
      end

    end
  end
end
