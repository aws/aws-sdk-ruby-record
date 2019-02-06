module Aws
  module Record
    module Transactions
      class << self

        # @example Usage Example
        #   class TableOne
        #     include Aws::Record
        #     string_attr :uuid, hash_key: true
        #   end
        #   
        #   class TableTwo
        #     include Aws::Record
        #     string_attr :hk, hash_key: true
        #     string_attr :rk, range_key: true
        #   end
        #   
        #   results = Aws::Record::Transactions.transact_find(
        #     transact_items: [
        #       TableOne.tfind_opts(key: { uuid: "uuid1234" }),
        #       TableTwo.tfind_opts(key: { hk: "hk1", rk: "rk1"}),
        #       TableTwo.tfind_opts(key: { hk: "hk2", rk: "rk2"})
        #     ]
        #   ) # => results.responses contains nil or marshalled items
        #   results.responses.map { |r| r.class } # [TableOne, TableTwo, TableTwo]
        #
        # Provides a way to run a transactional find across multiple DynamoDB
        # items, including transactions which get items across multiple actual
        # or virtual tables.
        #
        # @param [Hash] opts Options to pass through to
        #   {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#transact_get_items-instance_method Aws::DynamoDB::Client#transact_get_items},
        #   with the exception of the :transact_items API, which uses the
        #   +#tfind_opts+ operation on your model class to provide extra
        #   metadata used to marshal your items after retrieval.
        # @option opts [Array] :transact_items A set of +#tfind_opts+ results,
        #   such as those created by the usage example.
        # @option opts [Aws::DynamoDB::Client] :client Optionally, you can pass
        #   in your own client to use for the transaction calls.
        # @return [OpenStruct] Structured like the client API response from
        #   +#transact_get_items+, except that the +responses+ member contains
        #   +Aws::Record+ items marshaled into the classes used to call
        #   +#tfind_opts+ in each positional member. See the usage example.
        def transact_find(opts)
          opts = opts.dup
          client = opts.delete(:client) || dynamodb_client
          transact_items = opts.delete(:transact_items) # add nil check?
          model_classes = []
          client_transact_items = transact_items.map do |tfind_opts|
            model_class = tfind_opts.delete(:model_class)
            model_classes << model_class
            tfind_opts
          end
          request_opts = opts
          request_opts[:transact_items] = client_transact_items
          client_resp = client.transact_get_items(
            request_opts
          )
          responses = client_resp.responses
          index = -1
          ret = OpenStruct.new
          ret.consumed_capacity = client_resp.consumed_capacity
          ret.missing_items = []
          ret.responses = client_resp.responses.map do |item|
            index += 1
            if item.nil? || item.item.nil?
              missing_data = {
                model_class: model_classes[index],
                key: transact_items[index][:get][:key]
              }
              ret.missing_items << missing_data
              nil
            else
              # need to translate the item keys
              raw_item = item.item
              model_class = model_classes[index]
              new_item_opts = {}
              raw_item.each do |db_name, value|
                name = model_class.attributes.db_to_attribute_name(db_name)
                new_item_opts[name] = value
              end
              model_class.new(new_item_opts)
            end
          end
          ret
        end

        def transact_write(opts)
          opts = opts.dup
          client = opts.delete(:client) || dynamodb_client
          # fetch abstraction records
          transact_items = _transform_transact_write_items(
            opts.delete(:transact_items)
          )
          opts[:transact_items] = transact_items
          client.transact_write_items(opts)
        end

        # Configures the Amazon DynamoDB client used by global transaction
        # operations.
        #
        # Please note that this method is also called internally when you first
        # attempt to perform an operation against the remote end, if you have
        # not already configured a client. As such, please read and understand
        # the documentation in the AWS SDK for Ruby V3 around
        # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/#Configuration configuration}
        # to ensure you understand how default configuration behavior works.
        # When in doubt, call this method to ensure your client is configured
        # the way you want it to be configured.
      #
      # @param [Hash] opts the options you wish to use to create the client.
      #  Note that if you include the option +:client+, all other options
      #  will be ignored. See the documentation for other options in the
      #  {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#initialize-instance_method AWS SDK for Ruby V3}.
      # @option opts [Aws::DynamoDB::Client] :client allows you to pass in your
      #  own pre-configured client.
        def configure_client(opts = {})
          provided_client = opts.delete(:client)
          opts[:user_agent_suffix] = _user_agent(
            opts.delete(:user_agent_suffix)
          )
          client = provided_client || Aws::DynamoDB::Client.new(opts)
          @@dynamodb_client = client
        end

        # Gets the
        # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html}
        # instance that Transactions use. When called for the first time, if
        # {#configure_client} has not yet been called, will configure a new
        # client for you with default parameters.
      #
      # @return [Aws::DynamoDB::Client] the Amazon DynamoDB client instance.
        def dynamodb_client
          @@dynamodb_client ||= configure_client
        end

        private
        def _transform_transact_write_items(transact_items)
          transact_items.map do |item|
            # this code will assume users only provided one operation, and
            # will fail down the line if that assumption is wrong
            if save_record = item.delete(:save)
              _transform_save_record(save_record, item)
            elsif put_record = item.delete(:put)
              _transform_put_record(put_record, item)
            elsif delete_record = item.delete(:delete)
              _transform_delete_record(delete_record, item)
            elsif update_record = item.delete(:update)
              _transform_update_record(update_record, item)
            elsif check_record = item.delete(:check)
              _transform_check_record(check_record, item)
            else
              raise ArgumentError.new(
                "Invalid transact write item, must include an operation of "\
                  "type :save, :update, :delete, :update, or :check - #{item}"
              )
            end
          end
        end

        def _transform_save_record(save_record, opts)
          # determine if record is considered a new item or not
          # then create a put with conditions, or an update
          if save_record.send(:expect_new_item?)
            safety_expression = save_record.send(:prevent_overwrite_expression)
            if opts.include?(:condition_expression)
              raise Errors::TransactionalSaveConditionCollision.new(
                "Transactional write includes a :save operation that would "\
                  "result in a 'safe put' for the given item, yet a "\
                  "condition expression was also provided. This is not "\
                  "currently supported. You should rewrite this case to use "\
                  "a :put transaction, adding the existence check to your "\
                  "own condition expression if desired.\n"\
                  "\tItem: #{JSON.pretty_unparse(save_record.to_h)}\n"\
                  "\tExtra Options: #{JSON.pretty_unparse(opts)}"
              )
            else
              opts = opts.merge(safety_expression)
              _transform_put_record(save_record, opts)
            end
          else
            _transform_update_record(save_record, opts)
          end
        end

        def _transform_put_record(put_record, opts)
          # convert to a straight put
          opts[:table_name] = put_record.class.table_name
          opts[:item] = put_record.send(:_build_item_for_save)
          { put: opts }
        end

        def _transform_delete_record(delete_record, opts)
          # extract the key from each record to perform a deletion
          opts[:table_name] = delete_record.class.table_name
          opts[:key] = delete_record.send(:key_values)
          { delete: opts }
        end

        def _transform_update_record(update_record, opts)
          # extract dirty attribute changes to perform an update
          opts[:table_name] = update_record.class.table_name
          dirty_changes = update_record.send(:_dirty_changes_for_update)
          update_tuple = update_record.class.send(
            :_build_update_expression,
            dirty_changes
          )
          uex, exp_attr_names, exp_attr_values = update_tuple
          opts[:key] = update_record.send(:key_values)
          opts[:update_expression] = uex
          # need to combine expression attribute names and values
          if names = opts[:expression_attribute_names]
            opts[:expression_attribute_names] = exp_attr_names.merge(names)
          else
            opts[:expression_attribute_names] = exp_attr_names
          end
          if values = opts[:expression_attribute_values]
            opts[:expression_attribute_values] = exp_attr_values.merge(values)
          else
            opts[:expression_attribute_values] = exp_attr_values
          end
          { update: opts }
        end

        def _transform_check_record(check_record, opts)
          # check records are a pass-through
          { condition_check: opts.merge(check_record) }
        end

        def _user_agent(custom)
          if custom
            custom
          else
            " aws-record/#{VERSION}"
          end
        end

      end
    end
  end
end
