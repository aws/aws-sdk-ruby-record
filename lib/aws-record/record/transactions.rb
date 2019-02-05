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
        # @return [OpenStruct] Structured like the client API response from
        #   +#transact_get_items+, except that the +responses+ member contains
        #   +Aws::Record+ items marshaled into the classes used to call
        #   +#tfind_opts+ in each positional member. See the usage example.
        def transact_find(opts)
          transact_items = opts.delete(:transact_items) # add nil check?
          model_classes = []
          client_transact_items = transact_items.map do |tfind_opts|
            model_class = tfind_opts.delete(:model_class)
            model_classes << model_class
            tfind_opts
          end
          request_opts = opts
          request_opts[:transact_items] = client_transact_items
          client_resp = dynamodb_client.transact_get_items(
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

              model_classes[index].new(item.item)
            end
          end
          ret
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
