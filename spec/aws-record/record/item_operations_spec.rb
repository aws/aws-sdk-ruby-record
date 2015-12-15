module Aws
  module Record
    describe "ItemOperations" do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)
          date_attr(:date, range_key: true)
          string_attr(:body)
          boolean_attr(:bool, database_name: "my_boolean")
        end
      end

      let(:api_requests) { [] }

      let(:stub_client) do
        requests = api_requests
        client = Aws::DynamoDB::Client.new(stub_responses: true)
        client.handle do |context|
          requests << context.params
          @handler.call(context)
        end
        client
      end

      describe "Saving" do
        it 'can save an item to DynamoDB' do
          item = klass.new
          item.id = 1
          item.date = '2015-12-14'
          item.body = 'Hello!'
          item.configure_client(client: stub_client)
          item.save
          expect(api_requests).to eq([{
            table_name: "TestTable",
            item: {
              "id" => { n: "1" },
              "date" => { s: "2015-12-14" },
              "body" => { s: "Hello!" }
            }
          }])
        end
      end

    end
  end
end
