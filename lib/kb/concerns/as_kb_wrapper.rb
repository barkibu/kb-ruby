module KB
  module Concerns
    module AsKBWrapper
      extend ActiveSupport::Concern

      included do
        attr_writer :kb_model

        def save_underlying_kb_entity!
          kb_model.save!
          self.kb_key = kb_model.key if kb_model.key.present?
        end

        def destroy_underlying_kb_entity
          kb_model.destroy!
        end

        def reload(**options)
          @kb_model = nil
          super(**options)
        end
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
      class_methods do
        def wrap_kb(model:, skip_callback: false)
          before_save :save_underlying_kb_entity! unless skip_callback
          before_destroy :destroy_underlying_kb_entity unless skip_callback

          define_method(:kb_model) do
            underlying_kb_entity = @kb_model

            if underlying_kb_entity.blank?
              underlying_kb_entity = begin
                model.find kb_key
              rescue KB::ResourceNotFound
                model.new
              end

              @kb_model = underlying_kb_entity
            end

            underlying_kb_entity
          end

          singleton_class.instance_eval do
            define_method(:kb_find_by) do |**attributes|
              kb_model = model.all(attributes).first
              return nil if kb_model.nil?

              local_model = find_by(kb_key: kb_model.key)
              return nil if local_model.nil?

              local_model.kb_model = kb_model
              local_model
            end
          end
        end

        def kb_find_by!(**attributes)
          kb_find_by(attributes).presence || raise(ActiveRecord::RecordNotFound)
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
    end
  end
end
