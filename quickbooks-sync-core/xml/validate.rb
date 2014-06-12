#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'

Dir.chdir(File.dirname(__FILE__))
xsd = Nokogiri::XML::Schema(File.read("qbxmlops60.xsd"))

doc = Nokogiri::XML(STDIN.read)

xsd.validate(doc).each do |error|
  STDERR.puts error.message
  exit 1
end
