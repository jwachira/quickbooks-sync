module QuickBooksSync
  module ActsAsQuickBooksResource
    include QuickBooksSync

    class Repository < QuickBooksSync::Repository

      def resources
        ResourceSet.from_enumerator(enum_for(:each_resource))
      end

      def each_resource
        klasses = resource_classes.select(&:top_level?)

        klasses.each do |klass|
          klass.find_each(:include => klass.include_on_find) do |model|
            yield model.to_quick_books_resource
          end
        end
      end

      def [](id)
        type, id = id

        model = find_by_type_and_id type, id

        model.to_quick_books_resource if model
      end

      def add(resources)
        resources.each do |resource|
          unless resource.addable_to_remote?
            raise QuickBooksSync::InvalidOperation.new("Cannot add resource #{resource.inspect}")
          end
        end

        ActiveRecordWriter.new(self, resources).save
      end


      def update(resources)
        resources.each do |resource|
          unless resource.modable_on_remote?
            raise QuickBooksSync::InvalidOperation.new("Cannot update resource #{resource.inspect}")
          end

          klass = ar_class_from_resource_type resource.type

          model = find_by_klass_and_id klass, resource.quick_books_id

          restrict_to = klass.quick_books_config.update_only_fields || []

          attributes = ActiveRecordGenerator.new(self, resource, nil).update_attributes

          model.attributes = model.attributes.merge(attributes)
          model.changes_from_quick_books = true
          model.save!
        end
      end

      def update_metadata(metadata_by_id)
        metadata_by_id.each do |id, metadata|
          model = find_by_type_and_id *id
          # TODO: rationalize and DRY up
          metadata = metadata.with_indifferent_access

          attributes = [:vector_clock, :created_at, :updated_at, :quick_books_id].
            inject(model.attributes) do |_, key|
              if val = metadata[key]
                _.merge key => val
              else
                _
              end
            end

          model.attributes = attributes
          model.changes_from_quick_books = true
          model.save!
        end
      end

      def update_ids(ids)
        new_metadata = ids.map do |original_id, new_id|
          [original_id, {:quick_books_id => new_id}]
        end

        update_metadata new_metadata
      end

      def delete(ids)
        # TODO
      end

      def mark_as_synced
        resource_classes.select do |klass|
          klass.columns.any? {|column| column.name == "changed_since_sync" }
        end.each do |klass|
          klass.update_all :changed_since_sync => false
        end
      end

      private

      def find_by_klass_and_id(klass, id)
        (klass.first(:conditions => {:quick_books_id => id})) || (klass.first(:conditions => {:id => id.to_i}))
      end

      def find_by_type_and_id(type, id)
        klass = ar_class_from_resource_type(type)
        find_by_klass_and_id klass, id
      end

      class << self
        extend QuickBooksSync::Memoizable
        def resource_classes
          ActsAsQuickBooksResource.
            constants.sort.map do |klass_name|
            ActsAsQuickBooksResource.const_get(klass_name)
          end.select do |klass|
            klass.is_a?(Class) and klass < ActiveRecord::Base
          end
        end

        def ar_class_from_resource_type(type)
          QuickBooksSync::ActsAsQuickBooksResource.const_get(type)
        end

        def wrap_in_transaction(*methods)
          methods.each do |method_name|
            old_method = instance_method(method_name)

            define_method(method_name) do |*args|
              ActiveRecord::Base.transaction do
                old_method.bind(self).call(*args)
              end
            end
          end
        end

      end

      delegate :ar_class_from_resource_type, :resource_classes, :to => :"self.class"

      wrap_in_transaction :add, :update, :update_metadata, :update_ids, :delete, :mark_as_synced


    end

  end
end
