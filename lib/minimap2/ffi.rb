module Minimap2
    module FFI
      extend ::FFI::Library
  
      begin
        ffi_lib Minimap2.ffi_lib
      rescue LoadError => e
        raise LoadError, "Could not find #{Minimap2.ffi_lib}"
      end
  
      def self.attach_function(*)
        super
      rescue ::FFI::NotFoundError => e
        warn e.message
      end
    end
  end
  