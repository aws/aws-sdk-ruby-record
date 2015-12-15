require 'spec_helper'

module Aws

  describe 'Record' do
    let(:klass) do
      Class.new do
        include(Aws::Record)
      end
    end

    describe 'Keys' do
      it 'should be able to assign a hash key' do
        klass.string_attr(:mykey, hash_key: true)
        klass.string_attr(:other)
        expect(klass.hash_key.name).to eq('mykey')
      end

      it 'should be able to assign a hash and range key' do
        klass.string_attr(:mykey, hash_key: true)
        klass.string_attr(:ranged, range_key: true)
        klass.string_attr(:other)
        expect(klass.hash_key.name).to eq('mykey')
        expect(klass.range_key.name).to eq('ranged')
      end

      it 'raises an error on creation if no hash key exists'
    end

    describe 'Table' do
      it 'should have an implied table name from the class name' do
        ::UnitTestModel = Class.new do
          include(Aws::Record)
        end
        expect(UnitTestModel.table_name).to eq("UnitTestModel")
      end

      it 'should allow a custom table name to be specified' do
        expected = "ExpectedTableName"
        ::UnitTestModelTwo = Class.new do
          include(Aws::Record)
          set_table_name(expected)
        end
        expect(::UnitTestModelTwo.table_name).to eq(expected)
      end
    end

    describe 'Attributes' do
      it 'should create dynamic methods around attributes' do
        klass.string_attr(:text)
        x = klass.new
        x.text = "Hello world!"
        expect(x.text).to eq("Hello world!")
      end

      it 'should typecast an integer attribute' do
        klass.integer_attr(:num)
        x = klass.new
        x.num = "5"
        expect(x.num).to eq(5)
      end

      it 'should display a hash representation of attribute raw values' do
        klass.string_attr(:a)
        klass.string_attr(:b)
        x = klass.new
        x.a = "5"
        x.b = 5
        expect(x.to_h).to eq({a: "5", b: 5})
      end

      it 'should allow specification of a separate storage attribute name' do
        klass.string_attr(:a, database_attribute_name: 'column_a')
        klass.string_attr(:b)
        expect(klass.attributes[:a].database_name).to eq('column_a')
        expect(klass.attributes[:b].database_name).to eq('b')
      end
    end
  end

end
