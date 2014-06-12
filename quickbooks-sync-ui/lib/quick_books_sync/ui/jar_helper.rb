require 'java'
require 'fileutils'

module JarHelper
  extend self

  def in_jar?(path)
    path =~ /\.(jar|exe)\!/i
  end

  def extract_to_tempfile(path)
    base = File.basename(path)
    ext = File.extname(path)

    tempfile = Java::JavaIo::File.createTempFile(base, ext)

    extract_to_file path, tempfile, true
  end

  def extract_to_file(from, file, delete_on_exit)
    file.delete_on_exit if delete_on_exit

    output_stream = Java::JavaIo::FileOutputStream.new(file)
    output_channel = output_stream.get_channel

    url = "jar:" + from.gsub('\\', "/")

    input_stream = java::net::URL.new(url).open_stream
    input_channel = Java::JavaNioChannels::Channels.new_channel(input_stream)

    output_channel.transfer_from input_channel, 0, java::lang::Integer::MAX_VALUE

    [input_channel, output_channel, output_stream].each &:close

    file.path
  end

  def extract_to_path(from, to, delete_on_exit = false)
    extract_to_file from, Java::JavaIo::File.new(to), delete_on_exit
  end

  def string_from_resource(path)
    url = "jar:" + path.gsub('\\', "/")

    input_stream = java::net::URL.new(url).open_stream

    org.apache.commons.io.IOUtils.toString(input_stream)
  end

  def tmp_path
    path = File.join(Dir.tmpdir, Time.now.to_f.to_s + rand(2 ** 32).to_s)

    FileUtils.mkdir_p path

    path
  end
end

