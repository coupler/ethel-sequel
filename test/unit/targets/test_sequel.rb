require 'helper'

module TestTargets
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
      ::Sequel.stubs(:connect).returns(@database)
      @dataset = stub('dataset', :db => @database)
      @database.stubs(:[]).returns(@dataset)
    end

    test "subclass of Target" do
      assert_equal Target, Targets::Sequel.superclass
    end

    test "initialize with table name, uri, and options" do
      ::Sequel.expects(:connect).with('sqlite:/', :timeout => 1234).
        returns(@database)
      assert_nothing_raised do
        Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})
      end
    end

    test "using Sequel::Database" do
      ::Sequel.expects(:connect).never
      @database.expects(:kind_of?).with(::Sequel::Database).returns(true)
      Targets::Sequel.new(:foo, @database)
    end

    test "#prepare creates table if it doesn't exist" do
      target = Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})

      field_1 = stub('id field', :name => 'id', :type => :integer)
      target.add_field(field_1)

      field_2 = stub('foo field', :name => 'foo', :type => :string)
      target.add_field(field_2)

      seq = SequenceHelper.new('create table sequence')
      generator = stub('table generator')
      seq << @database.expects(:tables).returns([])
      seq << @database.expects(:create_table_generator).returns(generator)
      seq << generator.expects(:column).with('id', Integer)
      seq << generator.expects(:column).with('foo', String)
      seq << @database.expects(:create_table).with(:foo, generator)
      target.prepare
    end

    test "#prepare raises error if table exists" do
      target = Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})

      field_1 = stub('id field', :name => 'id', :type => :integer)
      target.add_field(field_1)

      field_2 = stub('foo field', :name => 'foo', :type => :string)
      target.add_field(field_2)

      @database.expects(:tables).returns([:foo])
      assert_raises { target.prepare }
    end

    test "#prepare forces table creation when force option is true" do
      target = Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234}, )
      target.force = true

      field_1 = stub('id field', :name => 'id', :type => :integer)
      target.add_field(field_1)

      field_2 = stub('foo field', :name => 'foo', :type => :string)
      target.add_field(field_2)

      seq = SequenceHelper.new('create table sequence')
      generator = stub('table generator')
      seq << @database.expects(:tables).returns([:foo])
      seq << @database.expects(:create_table_generator).returns(generator)
      seq << generator.expects(:column).with('id', Integer)
      seq << generator.expects(:column).with('foo', String)
      seq << @database.expects(:create_table!).with(:foo, generator)
      target.prepare
    end

    test "#flush" do
      target = Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})

      field_1 = stub('id field', :name => 'id', :type => :integer)
      target.add_field(field_1)

      field_2 = stub('foo field', :name => 'foo', :type => :string)
      target.add_field(field_2)

      target.add_row({:id => 1, :foo => 'bar'})
      target.add_row({:id => 2, :foo => 'baz'})
      @database.expects(:[]).with(:foo).returns(@dataset)
      @dataset.expects(:import).with([:id, :foo], [[1, 'bar'], [2, 'baz']])
      target.flush
    end

    test "#add_row automatically flushes when limit reached" do
      target = Targets::Sequel.new(:foo, 'sqlite:/', {:timeout => 1234})
      target.import_limit = 2

      field_1 = stub('id field', :name => 'id', :type => :integer)
      target.add_field(field_1)

      field_2 = stub('foo field', :name => 'foo', :type => :string)
      target.add_field(field_2)

      target.add_row({:id => 1, :foo => 'bar'})
      @database.expects(:[]).with(:foo).returns(@dataset)
      @dataset.expects(:import).with([:id, :foo], [[1, 'bar'], [2, 'baz']])
      target.add_row({:id => 2, :foo => 'baz'})

      target.add_row({:id => 3, :foo => 'test'})
      @database.expects(:[]).with(:foo).returns(@dataset)
      @dataset.expects(:import).with([:id, :foo], [[3, 'test'], [4, 'junk']])
      target.add_row({:id => 4, :foo => 'junk'})
    end
  end
end
