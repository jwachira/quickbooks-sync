require 'erb'

module QuickBooksSync
  class UI

    module Helpers
      RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__), "resources"))
      include ERB::Util

      def url(name)
        "file://#{resource(name)}"
      end

      def script(name)
        url = url("javascripts/#{name}")
        "<script type=\"text/javascript\" src=\"#{url}\"></script>"
      end

      def string_from_resource(path)
        location = resource_location(path)
        if JarHelper.in_jar?(location)
          JarHelper.string_from_resource(location)
        else
          File.read(location)
        end
      end

      def erb(name, context = {})
        Template.new(name, context).render
      end

      def resource(filename)
        local_path = resource_location(filename)

        if JarHelper.in_jar?(local_path)
          JarHelper.extract_to_tempfile(local_path)
        else
          local_path
        end
      end

      def resource_location(path)
        File.expand_path(
          File.join(RESOURCE_DIR, path)
        )
      end

    end

    class Template
      include Helpers
      attr_reader :name, :locals

      def initialize(name, options={})
        @name, @locals = name, (options[:locals] || {})
      end

      def this_erb
        file = "templates/#{name}"
        ERB.new(string_from_resource(file))
      end

      def render
        this_erb.result(binding)
      end

      def method_missing(name, *args)
        name = name.to_sym
        if locals.include?(name)
          locals[name]
        else
          super
        end
      end
    end

  end
end