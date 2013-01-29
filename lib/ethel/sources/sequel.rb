module Ethel
  module Sources
    class Sequel < Source
      def initialize(*args)
        if args.length == 1
          @dataset = args[0]
          @database = @dataset.db
        else
          @database = ::Sequel.connect(*args[1..-1])
          @dataset = @database[args[0]]
          @dataset_arg = args[0]
        end
      end

      def schema
        table =
          if @dataset_arg.nil?
            @dataset.first_source_table
          else
            @dataset_arg
          end

        @database.schema(table)
      end

      def each(&block)
        @dataset.each(&block)
      end
    end
  end
end
