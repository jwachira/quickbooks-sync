module ActsAsQuickBooksResource
  module Spec
    module Matchers
      class ActAsQuickBooksResource
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.to_quick_books_resource.type == @expected
        end

        def description
          "act as a QuickBooks resource of type '#{@expected}'"
        end

        def failure_message_for_should
          "expected #{@target.inspect} to act as a QuickBooks resource of type '#{@expected}'"
        end

        def failure_message_for_should_not
          "expected #{@target.inspect} not to act as a QuickBooks resource of type '#{@expected}'"
        end
      end

      class HaveQuickBooksId
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.class.quick_books_resource_configuration.id_method == @expected
        end

        def description
          "have its QuickBooks ID stored in '#{@expected}'"
        end

        def failure_message_for_should
          "expected #{@target.inspect} to have QuickBooks ID field '#{@expected}'"
        end

        def failure_message_for_should_not
          "expected #{@target.inspect} not to have QuickBooks ID field '#{@expected}'"
        end
      end

      class HaveQuickBooksMetadata
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.class.quick_books_resource_configuration.metadata_method == @expected
        end

        def description
          "have its QuickBooks metadata stored in '#{@expected}'"
        end

        def failure_message_for_should
          "expected #{@target.inspect} to have QuickBooks metadata field '#{@expected}'"
        end

        def failure_message_for_should_not
          "expected #{@target.inspect} not to have QuickBooks metadata field '#{@expected}'"
        end
      end

      class MapQuickBooksAttribute
        def initialize(expected_source)
          @expected_source = expected_source
        end

        def to(expected_target)
          @expected_target = expected_target
          self
        end

        def matches?(target)
          raise %{Expected target attribute name. For example:

            it { should map_quick_books_attribute(:name).to(:full_name) }

          } unless @expected_target
            
          @target = target
          @target.class.quick_books_resource_configuration.attributes[@expected_source] == @expected_target
        end

        def description
          "have the QuickBooks attribute '#{@expected_source}' mapped to its '#{@expected_target}' attribute"
        end

        def failure_message_for_should
          "expected #{@target.inspect} to map the QuickBooks attribute '#{@expected_source}' to '#{@expected_target}'"
        end

        def failure_message_for_should_not
          "expected #{@target.inspect} not to map the QuickBooks attribute '#{@expected_source}' to '#{@expected_target}'"
        end
      end

      def act_as_quick_books_resource(expected)
        ActAsQuickBooksResource.new(expected)
      end

      def have_quick_books_id(expected)
        HaveQuickBooksId.new(expected)
      end

      def have_quick_books_metadata(expected)
        HaveQuickBooksMetadata.new(expected)
      end

      def map_quick_books_attribute(expected)
        MapQuickBooksAttribute.new(expected)
      end
    end
  end
end
