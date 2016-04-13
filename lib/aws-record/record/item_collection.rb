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
        unless @result
          @result = @client.send(@search_method, @search_params)
        end
        @result.each_page do |page|
          items = _build_items_from_response(page.items, @model)
          items.each do |item|
            yield item
          end
        end
      end

      def empty?
        unless @result
          @result = @client.send(@search_method, @search_params)
        end
        @result.empty?
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

    end
  end
end
