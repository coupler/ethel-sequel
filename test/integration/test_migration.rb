require 'helper'

class TestMigration < Test::Unit::TestCase
  test "basic migration" do
    db = Sequel.sqlite
    db.create_table(:foo) do
      primary_key :id
      String :bar
    end
    db[:foo].import([:bar], [%w{123}, %w{456}])

    reader_options = {
      :type => 'sequel',
      :dataset => db[:foo]
    }
    writer_options = {
      :type => 'sequel',
      :database => db,
      :table_name => 'bar'
    }

    Ethel.migrate(reader_options, writer_options) do |m|
      m.cast('bar', :integer)
    end

    assert_include db.tables, :bar
    assert_equal([{:id => 1, :bar => 123}, {:id => 2, :bar => 456}],
      db[:bar].all)
  end
end
