require 'spec_helper'

module Aws
  describe 'Record' do

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


  end
end
