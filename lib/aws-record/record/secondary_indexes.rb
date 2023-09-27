# frozen_string_literal: true

module Aws
  module Record
    module SecondaryIndexes
      # @api private
      def self.included(sub_class)
        sub_class.instance_variable_set('@local_secondary_indexes', {})
        sub_class.instance_variable_set('@global_secondary_indexes', {})
        sub_class.extend(SecondaryIndexesClassMethods)
        inherit_indexes(sub_class) if Aws::Record.extends_record?(sub_class)
      end

      def self.inherit_indexes(klass)
        superclass_lsi = klass.superclass.instance_variable_get('@local_secondary_indexes').dup
        superclass_gsi = klass.superclass.instance_variable_get('@global_secondary_indexes').dup
        klass.instance_variable_set('@local_secondary_indexes', superclass_lsi)
        klass.instance_variable_set('@global_secondary_indexes', superclass_gsi)
      end

      private_class_method :inherit_indexes

      module SecondaryIndexesClassMethods
        # Creates a local secondary index for the model. Learn more about Local
        # Secondary Indexes in the
        # {http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LSI.html Amazon DynamoDB Developer Guide}.
        #
        # *Note*: {#local_secondary_indexes} is inherited from a parent model
        # when +local_secondary_index+ is explicitly specified in the parent.
        # @param [Symbol] name index name for this local secondary index
        # @param [Hash] opts
        # @option opts [Symbol] :range_key the range key used by this local
        #  secondary index. Note that the hash key MUST be the table's hash
        #  key, and so that value will be filled in for you.
        # @option opts [Hash] :projection a hash which defines which attributes
        #  are copied from the table to the index. See shape details in the
        #  {http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Types/Projection.html AWS SDK for Ruby V3 docs}.
        def local_secondary_index(name, opts)
          opts[:hash_key] = hash_key
          _validate_required_lsi_keys(opts)
          local_secondary_indexes[name] = opts
        end

        # Creates a global secondary index for the model. Learn more about
        # Global Secondary Indexes in the
        # {http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html Amazon DynamoDB Developer Guide}.
        #
        # *Note*: {#global_secondary_indexes} is inherited from a parent model
        # when +global_secondary_index+ is explicitly specified in the parent.
        # @param [Symbol] name index name for this global secondary index
        # @param [Hash] opts
        # @option opts [Symbol] :hash_key the hash key used by this global
        #  secondary index.
        # @option opts [Symbol] :range_key the range key used by this global
        #  secondary index.
        # @option opts [Hash] :projection a hash which defines which attributes
        #  are copied from the table to the index. See shape details in the
        #  {http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Types/Projection.html AWS SDK for Ruby V3 docs}.
        def global_secondary_index(name, opts)
          _validate_required_gsi_keys(opts)
          global_secondary_indexes[name] = opts
        end

        # Returns hash of local secondary index names to the index's attributes.
        #
        # *Note*: +local_secondary_indexes+ is inherited from a parent model when {#local_secondary_index}
        # is explicitly specified in the parent.
        # @return [Hash] hash of local secondary index names to the index's
        #   attributes.
        def local_secondary_indexes
          @local_secondary_indexes
        end

        # Returns hash of global secondary index names to the index's attributes.
        #
        # *Note*: +global_secondary_indexes+ is inherited from a parent model when {#global_secondary_index}
        # is explicitly specified in the parent.
        # @return [Hash] hash of global secondary index names to the index's
        #   attributes.
        def global_secondary_indexes
          @global_secondary_indexes
        end

        # @return [Hash] hash of the local secondary indexes in a form suitable
        #   for use in a table migration. For example, any attributes which
        #   have a unique database storage name will use that name instead.
        def local_secondary_indexes_for_migration
          _migration_format_indexes(local_secondary_indexes)
        end

        # @return [Hash] hash of the global secondary indexes in a form suitable
        #   for use in a table migration. For example, any attributes which
        #   have a unique database storage name will use that name instead.
        def global_secondary_indexes_for_migration
          _migration_format_indexes(global_secondary_indexes)
        end

        private

        def _migration_format_indexes(indexes)
          return nil if indexes.empty?

          indexes.collect do |name, opts|
            h = { index_name: name }
            h[:key_schema] = _si_key_schema(opts)
            hk = opts.delete(:hash_key)
            rk = opts.delete(:range_key)
            h = h.merge(opts)
            opts[:hash_key] = hk if hk
            opts[:range_key] = rk if rk
            h
          end
        end

        def _si_key_schema(opts)
          key_schema = [{
            key_type: 'HASH',
            attribute_name: @attributes.storage_name_for(opts[:hash_key])
          }]
          if opts[:range_key]
            key_schema << {
              key_type: 'RANGE',
              attribute_name: @attributes.storage_name_for(opts[:range_key])
            }
          end
          key_schema
        end

        def _validate_required_lsi_keys(params)
          unless params[:hash_key] && params[:range_key]
            raise ArgumentError, 'Local Secondary Indexes require a hash and range key!'
          end

          _validate_attributes_exist(params[:hash_key], params[:range_key])
        end

        def _validate_required_gsi_keys(params)
          raise ArgumentError, 'Global Secondary Indexes require at least a hash key!' unless params[:hash_key]

          if params[:range_key]
            _validate_attributes_exist(params[:hash_key], params[:range_key])
          else
            _validate_attributes_exist(params[:hash_key])
          end
        end

        def _validate_attributes_exist(*attr_names)
          missing = attr_names.reject do |attr_name|
            @attributes.present?(attr_name)
          end
          return if missing.empty?

          raise ArgumentError, "#{missing.join(', ')} not present in model attributes. " \
                               'Please ensure that attributes are defined in the model ' \
                               'class BEFORE defining an index on those attributes.'
        end
      end
    end
  end
end
