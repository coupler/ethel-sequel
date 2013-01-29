require 'helper'

module TestSources
  class TestSequel < Test::Unit::TestCase
    def self.const_missing(name)
      if Ethel.const_defined?(name)
        Ethel.const_get(name)
      else
        super
      end
    end

    def setup
      @database = stub('database')
      Sequel.stubs(:connect).returns(@database)
      @dataset = stub('dataset', :db => @database)
      @database.stubs(:[]).returns(@dataset)
    end

    test "subclass of Source" do
      assert_equal Sources::Sequel.superclass, Source
    end

    test "initialize with table name, uri, and options" do
      Sequel.expects(:connect).with('sqlite:/', :timeout => 1234).
        returns(@database)
      @database.expects(:[]).with(:foo).returns(@dataset)
      assert_nothing_raised do
        Sources::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})
      end
    end

    test "initialize with Sequel dataset" do
      @dataset.expects(:db).returns(@database)
      assert_nothing_raised { Sources::Sequel.new(@dataset) }
    end

    test "schema when initialized with Sequel dataset" do
      source = Sources::Sequel.new(@dataset)

      schema = [
        [:id, {
          :allow_null=>false, :default=>nil, :primary_key=>true,
          :db_type=>"integer", :type=>:integer, :ruby_default=>nil
        }],
        [:foo, {
          :allow_null=>true, :default=>nil, :primary_key=>false,
          :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil
        }]
      ]
      @dataset.expects(:first_source_table).returns(:foo)
      @database.expects(:schema).with(:foo).returns(schema)
      assert_equal schema, source.schema
    end

    test "schema when initialized with table_name, uri, and options" do
      source = Sources::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})

      schema = [
        [:id, {
          :allow_null=>false, :default=>nil, :primary_key=>true,
          :db_type=>"integer", :type=>:integer, :ruby_default=>nil
        }],
        [:foo, {
          :allow_null=>true, :default=>nil, :primary_key=>false,
          :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil
        }]
      ]
      @database.expects(:schema).with(:foo).returns(schema)
      assert_equal schema, source.schema
    end

    test "each" do
      source = Sources::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})

      row = {:id => 1, :foo => 123}
      @dataset.expects(:each).yields(row)
      source.each do |actual_row|
        assert_equal row, actual_row
      end
    end
  end
end
