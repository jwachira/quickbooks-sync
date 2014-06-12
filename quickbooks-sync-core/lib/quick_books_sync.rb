JRUBY = !!(defined?(RUBY_ENGINE) and RUBY_ENGINE =~ /jruby/) unless defined?(JRUBY)

if JRUBY
  require 'java'
end

# class Module
#   def profile(method)
#     module_eval "
#       def with_profile_#{method}(*args, &block)
#         start = Time.now
#         ret = without_profile_#{method}(*args, &block)
#         finish = Time.now
#         elapsed = finish - start
#         puts \"#{method}: \#\{elapsed\}\"
#
#         ret
#       end
#
#       alias without_profile_#{method} #{method}
#       alias #{method} with_profile_#{method}"
#   end
# end

unless defined?(Bundler) or (defined?(GEMS_LOADED) and GEMS_LOADED)
  require 'rubygems'
  require 'bundler'

  ENV['BUNDLE_GEMFILE'] = if JRUBY
      File.expand_path(File.dirname(__FILE__) + '/../jruby-gems/Gemfile')
    else
      File.expand_path(File.dirname(__FILE__) + '/../Gemfile')
    end
  Bundler.setup
end

require 'quick_books_sync/util'
require 'quick_books_sync/stub_logger'

require 'quick_books_sync/xml_support'
require 'quick_books_sync/client'
require 'quick_books_sync/client/connection'

require 'quick_books_sync/types'
require 'quick_books_sync/generate_types'

require 'quick_books_sync/field'

require 'quick_books_sync/resource'
require 'quick_books_sync/resource/types'

require 'quick_books_sync/resource/xml_reader'
require 'quick_books_sync/resource/json_reader'

require 'quick_books_sync/resource_set/business_logic'
require 'quick_books_sync/resource_set'
require 'quick_books_sync/session'
require 'quick_books_sync/repository'
require 'quick_books_sync/types'
require 'quick_books_sync/exceptions'

require 'quick_books_sync/repository/local'
require 'quick_books_sync/repository/quickbooks'
require 'quick_books_sync/repository/remote'

require 'quick_books_sync/error'
require 'quick_books_sync/conflict'
require 'quick_books_sync/resolution'
require 'quick_books_sync/logging'

require 'quick_books_sync/xsd_parser'
require 'quick_books_sync/penny_converter'

require 'quick_books_sync/http_authenticator'

begin
  require 'quick_books_sync/server'
rescue LoadError
end


