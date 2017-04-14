# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

    # +Aws::Record::TableConfig+ provides a DSL for describing and modifying
    # the remote configuration of your DynamoDB tables. A table configuration
    # object can perform intelligent comparisons and incremental migrations
    # versus the current remote configuration, if the table exists, or do a full
    # create if it does not. In this manner, table configuration becomes fully
    # declarative.
    #
    # @example A basic model with configuration.
    #   class Model
    #     include Aws::Record
    #     string_attr :uuid, hash_key: true
    #   end
    #
    #   table_config = Aws::Record::TableConfig.define do |t|
    #     t.model_class Model
    #     t.read_capacity_units 10
    #     t.write_capacity_units 5
    #   end
    #
    # @example Running a conditional migration on a basic model.
    #   table_config = Aws::Record::TableConfig.define do |t|
    #     t.model_class Model
    #     t.read_capacity_units 10
    #     t.write_capacity_units 5
    #   end
    #
    #   table_config.migrate! unless table_config.compatible?
    #
    # @example A model with a global secondary index.
    #   class Forum
    #     include Aws::Record
    #     string_attr     :forum_uuid, hash_key: true
    #     integer_attr    :post_id,    range_key: true
    #     string_attr     :post_title
    #     string_attr     :post_body
    #     string_attr     :author_username
    #     datetime_attr   :created_date
    #     datetime_attr   :updated_date
    #     string_set_attr :tags
    #     map_attr        :metadata, default_value: {}
    #
    #     global_secondary_index(
    #       :title,
    #       hash_key:  :forum_uuid,
    #       range_key: :post_title,
    #       projection_type: "ALL"
    #     )
    #   end
    #
    #   table_config = Aws::Record::TableConfig.define do |t|
    #     t.model_class Forum
    #     t.read_capacity_units 10
    #     t.write_capacity_units 5
    #
    #     t.global_secondary_index(:title) do |i|
    #       i.read_capacity_units 5
    #       i.write_capacity_units 5
    #     end
    #   end
    #
    class TableConfig

      attr_accessor :client

      class << self

        # Creates a new table configuration, using a DSL in the provided block.
        # The DSL has the following methods:
        # * +#model_class+ A class name reference to the +Aws::Record+ model
        #   class.
        # * +#read_capacity_units+ Sets the read capacity units for the table.
        # * +#write_capacity_units+ Sets the write capacity units for the table.
        # * +#global_secondary_index(index_symbol, &block)+ Defines a global
        #   secondary index with capacity attributes in a block:
        #   * +#read_capacity_units+ Sets the read capacity units for the
        #     index.
        #   * +#write_capacity_units+ Sets the write capacity units for the
        #     index.
        #
        # @example Defining a migration with a GSI.
        #   class Forum
        #     include Aws::Record
        #     string_attr     :forum_uuid, hash_key: true
        #     integer_attr    :post_id,    range_key: true
        #     string_attr     :post_title
        #     string_attr     :post_body
        #     string_attr     :author_username
        #     datetime_attr   :created_date
        #     datetime_attr   :updated_date
        #     string_set_attr :tags
        #     map_attr        :metadata, default_value: {}
        #
        #     global_secondary_index(
        #       :title,
        #       hash_key:  :forum_uuid,
        #       range_key: :post_title,
        #       projection_type: "ALL"
        #     )
        #   end
        #
        #   table_config = Aws::Record::TableConfig.define do |t|
        #     t.model_class Forum
        #     t.read_capacity_units 10
        #     t.write_capacity_units 5
        #
        #     t.global_secondary_index(:title) do |i|
        #       i.read_capacity_units 5
        #       i.write_capacity_units 5
        #     end
        #   end
        def define(&block)
          cfg = TableConfig.new
          cfg.instance_eval(&block)
          cfg.configure_client
          cfg
        end
      end

      # @api private
      def initialize
        @client_options = {}
        @global_secondary_indexes = {}
      end

      # @api private
      def model_class(model)
        @model_class = model
      end

      # @api private
      def read_capacity_units(units)
        @read_capacity_units = units
      end

      # @api private
      def write_capacity_units(units)
        @write_capacity_units = units
      end

      # @api private
      def global_secondary_index(name, &block)
        gsi = GlobalSecondaryIndex.new
        gsi.instance_eval(&block)
        @global_secondary_indexes[name] = gsi
      end

      # @api private
      def client_options(opts)
        @client_options = opts
      end

      # @api private
      def configure_client
        @client = Aws::DynamoDB::Client.new(@client_options)
      end

      # Performs a migration, if needed, against the remote table. If
      # +#compatible?+ would return true, the remote table already has the same
      # throughput, key schema, attribute definitions, and global secondary
      # indexes, so no further API calls are made. Otherwise, a DynamoDB table
      # will be created or updated to match your declared configuration.
      def migrate!
        _validate_required_configuration
        begin
          resp = @client.describe_table(table_name: @model_class.table_name)
          if _compatible_check(resp)
            nil
          else
            # Gotcha: You need separate migrations for indexes and throughput
            unless _throughput_equal(resp)
              @client.update_table(
                table_name: @model_class.table_name,
                provisioned_throughput: {
                  read_capacity_units: @read_capacity_units,
                  write_capacity_units: @write_capacity_units
                }
              )
              @client.wait_until(
                :table_exists,
                table_name: @model_class.table_name
              )
            end
            unless _gsi_superset(resp)
              @client.update_table(_update_index_opts(resp))
              @client.wait_until(
              :table_exists,
              table_name: @model_class.table_name
            )
            end
          end
        rescue DynamoDB::Errors::ResourceNotFoundException
          # Code Smell: Exception as control flow.
          # Can I use SDK ability to skip raising an exception for this?
          @client.create_table(_create_table_opts)
          @client.wait_until(:table_exists, table_name: @model_class.table_name)
        end
      end

      # Checks the remote table for compatibility. Similar to +#exact_match?+,
      # this will return +false+ if the remote table does not exist. It also
      # checks the keys, declared global secondary indexes, declared attribute
      # definitions, and throughput for exact matches. However, if the remote
      # end has additional attribute definitions and global secondary indexes
      # not defined in your config, will still return +true+. This allows for a
      # check that is friendly to single table inheritance use cases.
      #
      # @return [Boolean] true if remote is compatible, false otherwise.
      def compatible?
        begin
          resp = @client.describe_table(table_name: @model_class.table_name)
          _compatible_check(resp)
        rescue DynamoDB::Errors::ResourceNotFoundException
          false
        end
      end

      # Checks against the remote table's configuration. If the remote table
      # does not exist, guaranteed +false+. Otherwise, will check if the remote
      # throughput, keys, attribute definitions, and global secondary indexes
      # are exactly equal to your declared configuration.
      #
      # @return [Boolean] true if remote is an exact match, false otherwise.
      def exact_match?
        begin
          resp = @client.describe_table(table_name: @model_class.table_name)
          _throughput_equal(resp) &&
            _keys_equal(resp) &&
            _ad_equal(resp) &&
            _gsi_equal(resp)
        rescue DynamoDB::Errors::ResourceNotFoundException
          false
        end
      end

      private
      def _compatible_check(resp)
        _throughput_equal(resp) &&
          _keys_equal(resp) &&
          _ad_superset(resp) &&
          _gsi_superset(resp)
      end

      def _create_table_opts
        opts = {
          table_name: @model_class.table_name,
          provisioned_throughput: {
            read_capacity_units: @read_capacity_units,
            write_capacity_units: @write_capacity_units
          }
        }
        opts[:key_schema] = _key_schema
        opts[:attribute_definitions] = _attribute_definitions
        gsi = _global_secondary_indexes
        unless gsi.empty?
          opts[:global_secondary_indexes] = gsi 
        end
        opts
      end

      def _update_index_opts(resp)
        gsi_updates, attribute_definitions = _gsi_updates(resp)
        opts = {
          table_name: @model_class.table_name,
          global_secondary_index_updates: gsi_updates
        }
        unless attribute_definitions.empty?
          opts[:attribute_definitions] = attribute_definitions
        end
        opts
      end

      def _gsi_updates(resp)
        gsi_updates = []
        attributes_referenced = Set.new
        remote_gsis = resp.table.global_secondary_indexes
        local_gsis = _global_secondary_indexes
        remote_idx, local_idx = _gsi_index_names(remote_gsis, local_gsis)
        create_candidates = local_idx - remote_idx
        update_candidates = local_idx.intersection(remote_idx)
        create_candidates.each do |index_name|
          gsi = @model_class.global_secondary_indexes_for_migration.find do |i|
            i[:index_name].to_s == index_name
          end
          gsi[:key_schema].each do |k|
            attributes_referenced.add(k[:attribute_name])
          end
          # This may be a problem, check if I can maintain symbols.
          lgsi = @global_secondary_indexes[index_name.to_sym]
          gsi[:provisioned_throughput] = lgsi.provisioned_throughput
          gsi_updates << {
            create: gsi
          }
        end
        update_candidates.each do |index_name|
          # This may be a problem, check if I can maintain symbols.
          lgsi = @global_secondary_indexes[index_name.to_sym]
          gsi_updates << {
            update: {
              index_name: index_name,
              provisioned_throughput: lgsi.provisioned_throughput
            }
          }
        end
        attribute_definitions = _attribute_definitions
        incremental_attributes = attributes_referenced.map do |attr_name|
          attribute_definitions.find do |ad|
            ad[:attribute_name] == attr_name
          end
        end
        [gsi_updates, incremental_attributes]
      end

      def _key_schema
        _keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            key_type: type == :hash ? "HASH" : "RANGE"
          }
        end
      end

      def _attribute_definitions
        attribute_definitions = _keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            attribute_type: attr.dynamodb_type
          }
        end
        @model_class.global_secondary_indexes.each do |_, attributes|
          gsi_keys = [attributes[:hash_key]]
          gsi_keys << attributes[:range_key] if attributes[:range_key]
          gsi_keys.each do |name|
            attribute = @model_class.attributes.attribute_for(name)
            exists = attribute_definitions.any? do |ad|
              ad[:attribute_name] == attribute.database_name
            end
            unless exists
              attribute_definitions << {
                attribute_name: attribute.database_name,
                attribute_type: attribute.dynamodb_type
              }
            end
          end
        end
        attribute_definitions
      end

      def _keys
        @model_class.keys.inject({}) do |acc, (type, name)|
          acc[type] = @model_class.attributes.attribute_for(name)
          acc
        end
      end

      def _throughput_equal(resp)
        expected = resp.table.provisioned_throughput.to_h
        actual = {
          read_capacity_units: @read_capacity_units,
          write_capacity_units: @write_capacity_units
        }
        actual.all? do |k,v|
          expected[k] == v
        end
      end

      def _keys_equal(resp)
        remote_key_schema = resp.table.key_schema.map { |i| i.to_h }
        _array_unsorted_eql(remote_key_schema, _key_schema)
      end

      def _ad_equal(resp)
        remote_ad = resp.table.attribute_definitions.map { |i| i.to_h }
        _array_unsorted_eql(remote_ad, _attribute_definitions)
      end

      def _ad_superset(resp)
        remote_ad = resp.table.attribute_definitions.map { |i| i.to_h }
        _attribute_definitions.all? do |attribute_definition|
          remote_ad.include?(attribute_definition)
        end
      end

      def _gsi_superset(resp)
        remote_gsis = resp.table.global_secondary_indexes
        local_gsis = _global_secondary_indexes
        remote_idx, local_idx = _gsi_index_names(remote_gsis, local_gsis)
        if local_idx.subset?(remote_idx)
           _gsi_set_compare(remote_gsis, local_gsis)
        else
          # If we have any local indexes not on the remote table,
          # guaranteed false.
          false
        end
      end

      def _gsi_equal(resp)
        remote_gsis = resp.table.global_secondary_indexes
        local_gsis = _global_secondary_indexes
        remote_idx, local_idx = _gsi_index_names(remote_gsis, local_gsis)
        if local_idx == remote_idx
          _gsi_set_compare(remote_gsis, local_gsis)
        else
          false
        end
      end

      def _gsi_set_compare(remote_gsis, local_gsis)
        local_gsis.all? do |lgsi|
          rgsi = remote_gsis.find do |r|
            r.index_name == lgsi[:index_name].to_s
          end

          remote_key_schema = rgsi.key_schema.map { |i| i.to_h }
          ks_match = _array_unsorted_eql(remote_key_schema, lgsi[:key_schema])

          rpt = rgsi.provisioned_throughput.to_h
          lpt = lgsi[:provisioned_throughput]
          pt_match = lpt.all? do |k,v|
            rpt[k] == v
          end

          rp = rgsi.projection.to_h
          lp = lgsi[:projection]
          rp[:non_key_attributes].sort! if rp[:non_key_attributes]
          lp[:non_key_attributes].sort! if lp[:non_key_attributes]
          p_match = rp == lp

          ks_match && pt_match && p_match
        end
      end

      def _gsi_index_names(remote, local)
        remote_index_names = Set.new
        local_index_names = Set.new
        if remote
          remote.each do |gsi|
            remote_index_names.add(gsi.index_name)
          end
        end
        if local
          local.each do |gsi|
            local_index_names.add(gsi[:index_name].to_s)
          end
        end
        [remote_index_names, local_index_names]
      end

      def _global_secondary_indexes
        gsis = []
        model_gsis = @model_class.global_secondary_indexes_for_migration
        gsi_config = @global_secondary_indexes
        if model_gsis
          model_gsis.each do |mgsi|
            config = gsi_config[mgsi[:index_name]]
            # Validate throughput exists? Validate each throughput is in model?
            gsis << mgsi.merge(
              provisioned_throughput: config.provisioned_throughput
            )
          end
        end
        gsis
      end

      def _array_unsorted_eql(a, b)
        a.all? { |x| b.include?(x) } && b.all? { |x| a.include?(x) }
      end

      def _validate_required_configuration
        missing_config = []
        missing_config << 'model_class' unless @model_class
        missing_config << 'read_capacity_units' unless @read_capacity_units
        missing_config << 'write_capacity_units' unless @write_capacity_units
        unless missing_config.empty?
          msg = missing_config.join(', ')
          raise Errors::MissingRequiredConfiguration, 'Missing: ' + msg
        end
      end

      # @api private
      class GlobalSecondaryIndex
        attr_reader :provisioned_throughput

        def initialize
          @provisioned_throughput = {}
        end

        def read_capacity_units(units)
          @provisioned_throughput[:read_capacity_units] = units
        end

        def write_capacity_units(units)
          @provisioned_throughput[:write_capacity_units] = units
        end
      end

    end
  end
end
