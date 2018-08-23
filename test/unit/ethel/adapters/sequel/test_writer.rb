require 'helper'

module TestAdapters
  module TestSequel
    class TestWriter < Test::Unit::TestCase
      def new_writer(options)
        Ethel::Adapters::Sequel::Writer.new(options)
      end

      def setup
        @s_database = stub('database', :create_table => nil, :create_table! => nil)
        ::Sequel.stubs(:connect).returns(@s_database)
        @s_dataset = stub('dataset', :db => @s_database)
        @s_database.stubs(:[]).returns(@s_dataset)

        @s_generator = stub('table generator', :column => nil)
        @s_database.stubs(:create_table_generator).returns(@s_generator)
      end

      test "subclass of Ethel::Writer" do
        assert_equal Ethel::Writer, Ethel::Adapters::Sequel::Writer.superclass
      end

      test "initialize with table name and connect options" do
        Sequel.expects(:connect).with({
          :adapter => 'sqlite',
          :timeout => 1234
        }).returns(@s_database)

        assert_nothing_raised do
          new_writer({
            :table_name => 'foo',
            :connect_options => {
              :adapter => 'sqlite',
              :timeout => 1234
            }
          })
        end
      end

      test "initialize with Sequel database" do
        assert_nothing_raised do
          new_writer({
            :database => @s_database,
            :table_name => 'foo'
          })
        end
      end

      test "#prepare creates table if it doesn't exist" do
        writer = new_writer({
          :table_name => 'foo',
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

        dataset = stub('dataset')
        field_1 = stub('field 1', :name => 'id', :type => :integer)
        field_2 = stub('field 2', :name => 'foo', :type => :string)
        dataset.stubs(:each_field).multiple_yields([field_1], [field_2])

        @s_database.expects(:create_table_generator).returns(@s_generator)
        @s_generator.expects(:column).with('id', Integer)
        @s_generator.expects(:column).with('foo', String)
        @s_database.expects(:create_table).with(:foo, generator: @s_generator)

        writer.prepare(dataset)
      end

      test "#prepare forces table creation when force option is true" do
        writer = new_writer({
          :table_name => 'foo',
          :force => true,
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

        dataset = stub('dataset')
        field_1 = stub('field 1', :name => 'id', :type => :integer)
        field_2 = stub('field 2', :name => 'foo', :type => :string)
        dataset.stubs(:each_field).multiple_yields([field_1], [field_2])

        @s_database.expects(:create_table_generator).returns(@s_generator)
        @s_generator.expects(:column).with('id', Integer)
        @s_generator.expects(:column).with('foo', String)
        @s_database.expects(:create_table!).with(:foo, generator: @s_generator)

        writer.prepare(dataset)
      end

      test "#flush" do
        writer = new_writer({
          :table_name => 'foo',
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

        dataset = stub('dataset')
        field_1 = stub('field 1', :name => 'id', :type => :integer)
        field_2 = stub('field 2', :name => 'foo', :type => :string)
        dataset.stubs(:each_field).multiple_yields([field_1], [field_2])
        writer.prepare(dataset)

        writer.add_row({'id' => 1, 'foo' => 'bar'})
        writer.add_row({'id' => 2, 'foo' => 'baz'})

        @s_database.expects(:[]).with(:foo).returns(@s_dataset)
        @s_dataset.expects(:import).with([:id, :foo], [[1, 'bar'], [2, 'baz']])
        writer.flush
      end

      test "#add_row automatically flushes when limit reached" do
        writer = new_writer({
          :table_name => 'foo',
          :import_limit => 2,
          :connect_options => {
            :adapter => 'sqlite',
            :timeout => 1234
          }
        })

        dataset = stub('dataset')
        field_1 = stub('field 1', :name => 'id', :type => :integer)
        field_2 = stub('field 2', :name => 'foo', :type => :string)
        dataset.stubs(:each_field).multiple_yields([field_1], [field_2])
        writer.prepare(dataset)

        writer.add_row({'id' => 1, 'foo' => 'bar'})
        @s_database.expects(:[]).with(:foo).returns(@s_dataset)
        @s_dataset.expects(:import).with([:id, :foo], [[1, 'bar'], [2, 'baz']])
        writer.add_row({'id' => 2, 'foo' => 'baz'})

        writer.add_row({'id' => 3, 'foo' => 'test'})
        @s_database.expects(:[]).with(:foo).returns(@s_dataset)
        @s_dataset.expects(:import).with([:id, :foo], [[3, 'test'], [4, 'junk']])
        writer.add_row({'id' => 4, 'foo' => 'junk'})
      end

      test "registers itself" do
        assert_equal Ethel::Adapters::Sequel::Writer, Ethel::Writer['sequel']
      end
    end
  end
end
