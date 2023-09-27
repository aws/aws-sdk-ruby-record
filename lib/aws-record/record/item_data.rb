# frozen_string_literal: true

module Aws
  module Record
    # @api private
    class ItemData
      def initialize(model_attributes, opts)
        @data = {}
        @clean_copies = {}
        @dirty_flags = {}
        @model_attributes = model_attributes
        @track_mutations = opts[:track_mutations]
        @track_mutations = true if opts[:track_mutations].nil?
        @new_record = true
        @destroyed = false

        populate_default_values
      end
      attr_accessor :new_record, :destroyed

      def get_attribute(name)
        @model_attributes.attribute_for(name).type_cast(@data[name])
      end

      def set_attribute(name, value)
        @data[name] = value
      end

      def new_record?
        @new_record
      end

      def destroyed?
        @destroyed
      end

      def persisted?
        !(new_record? || destroyed?)
      end

      def raw_value(name)
        @data[name]
      end

      def clean!
        @dirty_flags = {}
        @model_attributes.attributes.each_key do |name|
          populate_default_values
          value = get_attribute(name)
          @clean_copies[name] = if @track_mutations
                                  _deep_copy(value)
                                else
                                  value
                                end
        end
      end

      def attribute_dirty?(name)
        if @dirty_flags[name]
          true
        else
          value = get_attribute(name)
          value != @clean_copies[name]
        end
      end

      def attribute_was(name)
        @clean_copies[name]
      end

      def attribute_dirty!(name)
        @dirty_flags[name] = true
      end

      def dirty
        @model_attributes.attributes.keys.each_with_object([]) do |name, acc|
          acc << name if attribute_dirty?(name)
          acc
        end
      end

      def dirty?
        !dirty.empty?
      end

      def rollback_attribute!(name)
        if attribute_dirty?(name)
          @dirty_flags.delete(name)
          set_attribute(name, attribute_was(name))
        end
        get_attribute(name)
      end

      def hash_copy
        @data.dup
      end

      def build_save_hash
        @data.each_with_object({}) do |name_value_pair, acc|
          attr_name, raw_value = name_value_pair
          attribute = @model_attributes.attribute_for(attr_name)
          if !raw_value.nil? || attribute.persist_nil?
            db_name = attribute.database_name
            acc[db_name] = attribute.serialize(raw_value)
          end
          acc
        end
      end

      def populate_default_values
        @model_attributes.attributes.each do |name, attribute|
          next if (default_value = attribute.default_value).nil?
          next unless @data[name].nil?

          @data[name] = default_value
        end
      end

      private

      def _deep_copy(obj)
        Marshal.load(Marshal.dump(obj))
      end
    end
  end
end
