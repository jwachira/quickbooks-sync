SPEC_DIR = File.expand_path(File.dirname(__FILE__) + '/spec')
LIB_DIR = File.expand_path(File.dirname(__FILE__) + '/lib')

def silently
  old_stderr = $stderr
  $stderr = StringIO.new
  yield
ensure
  $stderr = old_stderr
end

JRUBY = !!(defined?(RUBY_ENGINE) and RUBY_ENGINE =~ /jruby/) unless defined?(JRUBY)

if JRUBY
  ENV['BUNDLE_GEMFILE'] =  File.expand_path(File.dirname(__FILE__) + '/jruby-gems/Gemfile')
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
  end

  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_files = FileList[SPEC_DIR + '/**/*_spec.rb']
    t.spec_opts = ["--format specdoc"]
  end
rescue LoadError => e
  STDERR.puts "Warning: #{e.message}"
end

task :default => [ :spec, :features ]

QUICKBOOKS_XSD = File.expand_path(File.dirname(__FILE__) + '/xml/qbxmlops60.xsd')
TYPES_FILE = "#{LIB_DIR}/quick_books_sync/types.rb"
TYPES_TEMPLATE = File.expand_path(File.dirname(__FILE__) + '/resources/types.rb.erb')

desc "Build types from XSD"
task :build_types_from_xsd => :environment do
  require 'pp'
  require 'erb'

  io = StringIO.new
  output = QuickBooksSync::XsdParser.generate QUICKBOOKS_XSD
  PP.pp output, io
  types_string = io.string

  template = ERB.new(File.read(TYPES_TEMPLATE))

  File.open(TYPES_FILE, 'w') do |f|
    f.puts template.result(binding)
  end
end

desc "Generate HTML documentation from QBXML XSD"
task :xsd_doc do
  require "xml/xslt"

  xslt = XML::XSLT.new()
  xslt.xml = File.dirname(__FILE__) + "/xml/qbxml60.xsd"
  xslt.xsl = File.dirname(__FILE__) + "/xml/xs3p.xsl"
  File.open(File.dirname(__FILE__) + '/xml/qbxml60.xsd.doc.html', 'w') do |file| 
    file << xslt.serve()
  end
end

task :environment do
  $: << LIB_DIR
  require 'quick_books_sync'
end
