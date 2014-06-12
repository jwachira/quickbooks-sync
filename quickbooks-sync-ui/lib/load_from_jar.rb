require 'ffi'
require 'tempfile'

module FFI
  module Library
    def ffi_lib_with_unextract_jars(*libs)
      # raise libs.inspect
      tmp_dir = File.join(Dir.tmpdir, Time.now.to_f.to_s + rand(2 ** 32).to_s)

      libs = libs.map do |lib|
        if DllExtractor.is_dll_in_jar?(lib)
          DllExtractor.copy_dll_to_tempfile(lib, tmp_dir)
        else
          lib
        end
      end

      ffi_lib_without_unextract_jars *libs
    end

    alias :ffi_lib_without_unextract_jars :ffi_lib
    alias :ffi_lib :ffi_lib_with_unextract_jars

  end

  module DllExtractor
    extend self

    def copy_dll_to_tempfile(dll, tmp_dir)
      FileUtils.mkdir_p tmp_dir

      destination = File.join(tmp_dir, File.basename(dll))

      copy_from_jar dll, destination

      dependencies = DllDependencies.find_for(destination).map {|dependency|
        File.join(File.dirname(dll), dependency)
      }

      dependencies.each do |dependency|
        begin
          copy_dll_to_tempfile(dependency, tmp_dir)
        rescue java.io.FileNotFoundException => e
        end
      end

      destination.tr("/", "\\")
    end

    def is_dll_in_jar?(lib)
      lib =~ /\!/ and lib =~ /\.dll$/i
    end

    def copy_from_jar(from, to)
      tempfile = Java::JavaIo::File.new to
      tempfile.delete_on_exit

      output_stream = Java::JavaIo::FileOutputStream.new(tempfile)
      output_channel = output_stream.get_channel

      url = "jar:" + from.gsub('\\', "/")

      input_stream = java::net::URL.new(url).open_stream
      input_channel = Java::JavaNioChannels::Channels.new_channel(input_stream)

      output_channel.transfer_from input_channel, 0, java::lang::Integer::MAX_VALUE

      [input_channel, output_channel, output_stream].each &:close
    end

  end

  module DllDependencies
    extend FFI::Library

    BIND_NO_BOUND_IMPORTS = 0x00000001
    BIND_NO_UPDATE = 0x00000002
    BIND_ALL_IMAGES = 0x00000004
    BindImportModuleFailed = 3
    BindImportModule = 5

    ffi_lib "imagehlp.dll"
    ffi_convention :stdcall

    # BOOL StatusRoutine(
    #   __in  IMAGEHLP_STATUS_REASON Reason,
    #   __in  PSTR ImageName,
    #   __in  PSTR DllName,
    #   __in  ULONG_PTR Va,
    #   __in  ULONG_PTR Parameter
    # );

    callback :bind_image_callback, [:int, :pointer, :string, :pointer, :pointer], :bool

    # BOOL BindImageEx(
    #   __in  DWORD Flags,
    #   __in  PSTR ImageName,
    #   __in  PSTR DllPath,
    #   __in  PSTR SymbolPath,
    #   __in  PIMAGEHLP_STATUS_ROUTINE StatusRoutine
    # );

    attach_function :BindImageEx, [:int, :pointer, :pointer, :pointer, :bind_image_callback], :bool

    module_function

    def find_for(dll)
      name = FFI::MemoryPointer.from_string(dll)

      required_dlls = []

      callback = Proc.new do |reason, name, dll_name, va, param|
        required_dlls << dll_name if reason == BindImportModuleFailed or reason == BindImportModule
      end

      BindImageEx(
        BIND_NO_BOUND_IMPORTS | BIND_NO_UPDATE,
        name,
        nil,
        nil,
        callback
      )

      required_dlls
    end

  end


end



$:.reject! {|p| p == "."}
$: << File.expand_path(File.dirname(__FILE__))

def require_with_jar_override(path)
  require_without_jar_override path unless path =~ /\.jar$/
end

alias :require_without_jar_override :require
alias :require :require_with_jar_override


require 'bundled_gems'

require 'quick_books_sync/ui/jar_helper'
require 'quick_books_sync'
require 'quick_books_sync/ui'
