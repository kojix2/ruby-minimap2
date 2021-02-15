# frozen_string_literal: true

require "ffi"

module FFI
  class BitStruct < Struct
    class << self
      # def union_layout(*args)
      #   Class.new(FFI::Union) { layout(*args) }
      # end

      # def struct_layout(*args)
      #   Class.new(FFI::Struct) { layout(*args) }
      # end

      module BitFieldsModule
        def [](name)
          bit_fields = self.class.bit_fields_map
          parent, start, width = bit_fields[name]
          if parent
            (super(parent) >> start) & ((1 << width) - 1)
          else
            super(name)
          end
        end
      end
      private_constant :BitFieldsModule

      def bit_fields_map
        @bit_fields
      end

      def bitfields(*args)
        unless instance_variable_defined?(:@bit_fields)
          @bit_fields = {}
          prepend BitFieldsModule
        end

        parent = args.shift
        labels = []
        widths = []
        args.each_slice(2) do |l, w|
          labels << l
          widths << w
        end
        starts = widths.inject([0]) do |result, w|
          result << (result.last + w)
        end
        labels.zip(starts, widths).each do |l, s, w|
          @bit_fields[l] = [parent, s, w]
        end
      end
    end
  end
end
