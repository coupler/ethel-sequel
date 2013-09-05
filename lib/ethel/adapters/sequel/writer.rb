module Ethel
  module Adapters
    module Sequel
      class Writer < Ethel::Writer
        def initialize(options)
          if options[:database]
            @database = options[:database]
          else
            @database = ::Sequel.connect(options[:connect_options])
          end
          @table_name = options[:table_name].to_sym
          @force = options[:force]
          @import_limit = options[:import_limit] || 10_000
          @field_names = []
          @field_names_sym = []
          @rows = []
        end

        def prepare(dataset)
          generator = @database.create_table_generator
          dataset.each_field do |field|
            type =
              case field.type
              when :integer
                Integer
              when :string
                String
              end
            generator.column(field.name, type)
            @field_names << field.name
            @field_names_sym << field.name.to_sym
          end

          if @force
            @database.create_table!(@table_name, generator)
          else
            @database.create_table(@table_name, generator)
          end
        end

        def add_row(row)
          @rows << row
          flush if @rows.length >= @import_limit
        end

        def flush
          dataset = @database[@table_name]
          data = @rows.collect { |r| r.values_at(*@field_names) }
          dataset.import(@field_names_sym, data)
          @rows.clear
        end
      end

      Ethel::Writer.register('sequel', Writer)
    end
  end
end
