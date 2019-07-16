module Aws
  module Record
    class BuildableSearch
      SUPPORTED_OPERATIONS = [:query, :scan]

      def initialize(operation:, model:)
        if SUPPORTED_OPERATIONS.include?(operation)
          @operation = operation
        else
          raise ArgumentError.new("Unsupported operation: #{operation}")
        end
        @model = model
        @params = {}
        @next_name = "BUILDERA"
        @next_value = "buildera"
      end

      def on_index(index)
        @params[:index_name] = index
        self
      end

      def key_expr(statement_str, *subs)
        names = @params[:expression_attribute_names]
        if names.nil?
          @params[:expression_attribute_names] = {}
          names = @params[:expression_attribute_names]
        end
        values = @params[:expression_attribute_values]
        if values.nil?
          @params[:expression_attribute_values] = {}
          values = @params[:expression_attribute_values]
        end
        _key_pass(statement_str, names)
        _apply_values(statement_str, subs, values)
        @params[:key_condition_expression] = statement_str
        self
      end

      def filter_expr(statement_str, *subs)
        names = @params[:expression_attribute_names]
        if names.nil?
          @params[:expression_attribute_names] = {}
          names = @params[:expression_attribute_names]
        end
        values = @params[:expression_attribute_values]
        if values.nil?
          @params[:expression_attribute_values] = {}
          values = @params[:expression_attribute_values]
        end
        _key_pass(statement_str, names)
        _apply_values(statement_str, subs, values)
        @params[:filter_expression] = statement_str
        self
      end

      def limit(size)
        @params[:limit] = size
        self
      end

      def run!
        @model.send(@operation, @params)
      end

      private
      def _key_pass(statement, names)
        statement.gsub!(/:(\w+)/) do |match|
          key = match.gsub!(':','').to_sym 
          key_name = @model.attributes.storage_name_for(key)
          if key_name
            sub_name = _next_name
            raise "Substitution collision!" if names[sub_name]
            names[sub_name] = key_name
            sub_name
          else
            raise "No such key #{key}"
          end
        end
      end

      def _apply_values(statement, subs, values)
        count = 0
        statement.gsub!(/[?]/) do |match|
          sub_value = _next_value
          raise "Substitution collision!" if values[sub_value]
          values[sub_value] = subs[count]
          count += 1
          sub_value
        end
        unless count == subs.size
          raise "Expected #{count} values in the substitution set, but found #{subs.size}"
        end
      end

      def _next_name
        ret = "#" + @next_name
        @next_name.next!
        ret
      end

      def _next_value
        ret = ":" + @next_value
        @next_value.next!
        ret
      end
    end
  end
end
