module Ethel
  module Targets
    class Sequel < Target
      attr_accessor :force, :import_limit

      def initialize(table_name, *database_args)
        super

        @database = ::Sequel.connect(*database_args)
        @table_name = table_name
        @fields = []
        @rows = []

        @force = false
        @import_limit = 10_000
      end

      def add_field(field)
        @fields << field
      end

      def prepare
        exists = @database.tables.include?(@table_name)
        if exists && !@force
          raise "Table #{@table_name} already exists"
        else
          generator = @database.create_table_generator
          @fields.each do |field|
            type =
              case field.type
              when :integer
                Integer
              when :string
                String
              end
            generator.column(field.name, type)
          end
          if exists
            @database.create_table!(@table_name, generator)
          else
            @database.create_table(@table_name, generator)
          end
        end
      end

      def add_row(row)
        @rows << row

        flush if @rows.length >= @import_limit
      end

      def flush
        dataset = @database[@table_name]
        keys = @fields.collect { |field| field.name.to_sym }
        dataset.import(keys, @rows.collect { |r| r.values_at(*keys) })
        @rows.clear
      end
    end
  end
end
