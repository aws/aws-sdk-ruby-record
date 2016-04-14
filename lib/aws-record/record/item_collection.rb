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
          model.attributes.each do |name, attr|
            data[name] = attr.extract(item)
          end
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
