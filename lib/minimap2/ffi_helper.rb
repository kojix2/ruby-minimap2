# frozen_string_literal: true

require "ffi"

module FFI
  class Struct
    class << self
      def union_layout(*args)
        Class.new(FFI::Union) { layout(*args) }
      end

      def struct_layout(*args)
        Class.new(FFI::Struct) { layout(*args) }
      end

      def bitfields(*args)
        @bit_field_table ||= {}
        n = args.shift
        keys, values = args.each_slice(2).to_a.transpose
        starts = values.inject([0]) { |x, y| x + [x.last + y] }
        keys.each_with_index do |k, i|
          @bit_field_table[k] = [n, starts[i], values[i]]
        end

        if @prepend_module.nil?
          bit_field_table = @bit_field_table
          @prepend_module = Module.new do
            define_method("[]") do |name|
              if bit_field_table.key?(name)
                n, s, v = bit_field_table[name]
                (super(n) >> s) & ((1 << v) - 1)
              else
                super(name)
              end
            end
          end
          prepend @prepend_module
        end
      end
    end
  end
end
