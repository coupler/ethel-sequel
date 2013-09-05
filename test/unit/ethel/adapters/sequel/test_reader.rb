require 'helper'

module TestAdapters
  module TestSequel
    class TestReader < Test::Unit::TestCase
      def new_reader(options)
        Ethel::Adapters::Sequel::Reader.new(options)
      end

      def setup
        @s_database = stub('database')
        Sequel.stubs(:connect).returns(@s_database)
        @s_dataset = stub('dataset', :db => @s_database, :first_source_table => :foo)
        @s_database.stubs(:[]).returns(@s_dataset)
      end

      test "subclass of Ethel::Reader" do
        assert_equal Ethel::Reader, Ethel::Adapters::Sequel::Reader.superclass
      end

      test "initialize with table name and connect options" do
        Sequel.expects(:connect).with(:adapter => 'sqlite', :timeout => 1234).
          returns(@s_database)
        @s_database.expects(:[]).with(:foo).returns(@s_dataset)
        assert_nothing_raised do
          new_reader({
            :table_name => 'foo',
            :connect_options => {
              :adapter => 'sqlite',
              :timeout => 1234
            }
          })
        end
      end

      test "initialize with Sequel dataset" do
        @s_dataset.expects(:db).returns(@s_database)
        @s_dataset.expects(:first_source_table).returns(:foo)
        assert_nothing_raised do
          new_reader(:dataset => @s_dataset)
        end
      end

      test "read when initialized with Sequel dataset" do
        reader = new_reader(:dataset => @s_dataset)

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
        @s_database.expects(:schema).with(:foo).returns(schema)

        dataset = stub('dataset')
        field_1 = stub('field 1')
        Ethel::Field.expects(:new).
          with('id', :type => :integer).returns(field_1)
        dataset.expects(:add_field).with(field_1)
        field_2 = stub('field 2')
        Ethel::Field.expects(:new).
          with('foo', :type => :string).returns(field_2)
        dataset.expects(:add_field).with(field_2)

        reader.read(dataset)
      end

      test "read when initialized with table_name and connect options" do
        reader = new_reader({
          :table_name => 'foo',
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

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
        @s_database.expects(:schema).with(:foo).returns(schema)

        dataset = stub('dataset')
        field_1 = stub('field 1')
        Ethel::Field.expects(:new).
          with('id', :type => :integer).returns(field_1)
        dataset.expects(:add_field).with(field_1)
        field_2 = stub('field 2')
        Ethel::Field.expects(:new).
          with('foo', :type => :string).returns(field_2)
        dataset.expects(:add_field).with(field_2)

        reader.read(dataset)
      end

      test "each_row" do
        reader = new_reader({
          :table_name => 'foo',
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

        row = {:id => 1, :foo => 123}
        @s_dataset.expects(:each).yields(row)
        rows = reader.to_enum(:each_row).to_a
        assert_equal [{'id' => 1, 'foo' => 123}], rows
      end

      test "registers itself" do
        assert_equal Ethel::Adapters::Sequel::Reader, Ethel::Reader['sequel']
      end
    end
  end
end
