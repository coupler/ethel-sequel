module Ethel
  module Adapters
    module Sequel
      class Reader < Ethel::Reader
        def initialize(options)
          if options[:dataset]
            @dataset = options[:dataset]
            @table_name = @dataset.first_source_table
            @database = @dataset.db
          else
            @database = ::Sequel.connect(options[:connect_options])
            @table_name = options[:table_name].to_sym
            @dataset = @database[@table_name]
          end
        end

        def read(dataset)
          @database.schema(@table_name).each do |(name, info)|
            dataset.add_field(Field.new(name.to_s, :type => info[:type]))
          end
        end

        def each_row(&block)
          @dataset.each do |row|
            row.keys.each do |key|
              row[key.to_s] = row.delete(key)
            end
            yield row
          end
        end
      end

      Ethel::Reader.register('sequel', Reader)
    end
  end
end
