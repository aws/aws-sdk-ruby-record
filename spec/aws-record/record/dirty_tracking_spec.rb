# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'spec_helper'
require 'securerandom'

describe Aws::Record::DirtyTracking do

  let(:klass) do
    Class.new do
      include(Aws::Record)

      set_table_name(:test_table)

      string_attr(:mykey, hash_key: true)
      string_attr(:body)
    end
  end

  let(:instance) { klass.new }

  let(:stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

  describe '#[attribute]_dirty?' do 

    it "should return whether the attribute is dirty or clean" do 
      expect(instance.mykey_dirty?).to be false

      instance.mykey = SecureRandom.uuid
      expect(instance.mykey_dirty?).to be true
    end

    it "should not reflect changes to the original value as dirty" do 
      instance.mykey = nil
      expect(instance.mykey_dirty?).to be false

      instance.mykey = SecureRandom.uuid
      expect(instance.mykey_dirty?).to be true

      instance.mykey = nil
      expect(instance.mykey_dirty?).to be false
    end
  end

  describe '#[attribute]_dirty!' do 

    before(:each) do 
      instance.mykey = "Alex"
      instance.clean!
    end

    it "should mark the attribute as dirty" do 
      instance.mykey << 'i'
      expect(instance.dirty?).to be false

      instance.mykey_dirty!
      expect(instance.dirty?).to be true 
      expect(instance.mykey_was).to eq 'Alexi'
      expect(instance.mykey).to eq 'Alexi'

      instance.mykey << 's'
      expect(instance.mykey_was).to eq 'Alexi'
      expect(instance.mykey).to eq 'Alexis'
    end

  end

  describe '#[attribute]_was' do 

    it "should return the last known clean value" do 
      expect(instance.mykey_was).to be nil

      instance.mykey = SecureRandom.uuid
      expect(instance.mykey_was).to be nil
    end

  end

  describe "#clean!" do 

    it "should mark the record as clean" do 
      instance.mykey = SecureRandom.uuid
      expect(instance.dirty?).to be true
      expect(instance.mykey_was).to be nil

      instance.clean!
      expect(instance.dirty?).to be false
      expect(instance.mykey_was).to eq instance.mykey
    end

  end

  describe '#dirty' do 

    it "should return an array of dirty attributes" do 
      expect(instance.dirty).to match_array []

      instance.mykey = SecureRandom.uuid
      expect(instance.dirty).to match_array [:mykey]

      instance.body = SecureRandom.uuid
      expect(instance.dirty).to match_array [:mykey, :body]
    end 

  end

  describe '#dirty?' do 

    it "should return whether the record is dirty or clean" do 
      expect(instance.dirty?).to be false

      instance.mykey = SecureRandom.uuid
      expect(instance.dirty?).to be true
    end

  end

  describe "#reload!" do 
    before(:each) do 
      klass.configure_client(client: stub_client)
    end

    let(:reloaded_instance) {
      item = klass.new
      item.mykey = SecureRandom.uuid
      item.body = SecureRandom.uuid
      item.clean!
      item 
    }

    it 'can reload an item using find' do 
      expect(klass).to receive(:find).with({ mykey: reloaded_instance.mykey }).and_return(reloaded_instance)

      instance.mykey = reloaded_instance.mykey
      instance.body = SecureRandom.uuid

      instance.reload!

      expect(instance.body).to eq reloaded_instance.body
    end

    it 'raises an error when find returns nil' do 
      instance.mykey = SecureRandom.uuid

      expect(klass).to receive(:find).with({ mykey: instance.mykey }).and_return(nil)

      expect { instance.reload! }.to raise_error Aws::Record::Errors::NotFound
    end

    it "should mark the item as clean" do 
      instance.mykey = SecureRandom.uuid
      expect(instance).to receive(:clean!)

      instance.reload!
    end    
  end

  describe '#rollback_[attribute]!' do 

    it "should restore the attribute to its last known clean value" do 
      instance.mykey = SecureRandom.uuid

      instance.rollback_mykey!
      expect(instance.mykey).to be instance.mykey_was
    end 

  end

  describe "#rollback!" do

    before(:each) do 
      instance.mykey = SecureRandom.uuid
      instance.body = SecureRandom.uuid
    end 

    it "should restore the provided attributes" do 
      instance.rollback!(:mykey)
      expect(instance.mykey).to eq instance.mykey_was
    end

    context "when no attributes are provided" do 

      it "should restore all attributes" do 
        instance.rollback!

        expect(instance.dirty?).to be false

        expect(instance.mykey).to eq instance.mykey_was
        expect(instance.body).to eq instance.body_was
      end

    end

  end

  describe "#save" do 
    before(:each) do 
      klass.configure_client(client: stub_client)
    end

    it "should mark the item as clean" do 
      instance.mykey = SecureRandom.uuid
      expect(instance).to receive(:clean!)

      instance.save
    end    
  end

end
