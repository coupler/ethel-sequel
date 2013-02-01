require 'helper'

class TestMigration < Test::Unit::TestCase
  test "basic migration" do
    db = Sequel.sqlite
    db.create_table(:foo) do
      primary_key :id
      String :bar
    end
    db[:foo].import([:bar], [%w{123}, %w{456}])
    source = Ethel::Sources::Sequel.new(db[:foo])
    target = Ethel::Targets::Sequel.new(:bar, db)
    migration = Ethel::Migration.new(source, target)
    migration.copy(source.fields[:id])
    migration.cast(source.fields[:bar], :integer)
    migration.run

    assert_include db.tables, :bar
    assert_equal([{:id => 1, :bar => 123}, {:id => 2, :bar => 456}],
      db[:bar].all)
  end
end
