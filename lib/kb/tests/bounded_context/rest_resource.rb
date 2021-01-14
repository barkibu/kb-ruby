module BoundedContext
  module RestResource
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      def resource_by_key(resource, key)
        entity = find_resource(resource, key)
        return json_response 404, {} if entity.nil?

        json_response 200, entity
      end

      def json_response(response_code, body_content)
        content_type :json
        status response_code
        body body_content.to_json
      end

      def on_index_action(name, _version)
        json_response 200, filter_resources(resource_state(name), params)
      end

      def filter_resources(resources, filters)
        resources.select do |item|
          filters.slice(*filterable_attributes).reduce(true) do |sum, (key, value)|
            sum && (value.blank? \
                    || (item.fetch(key, '') || '').downcase.include?(value.downcase))
          end
        end
      end

      def on_show_action(name, _version)
        resource_by_key name, params['key']
      end

      def on_create_action(name, _version)
        resource = JSON.parse(request.body.read)
        resource = resource.merge 'key' => SecureRandom.uuid
        resource_state(name) << resource
        json_response 201, resource
      end

      def on_update_action(name, _version)
        resource_to_update = find_resource name, params['key']

        return json_response 404, {} if resource_to_update.nil?

        partial_resource = JSON.parse(request.body.read)
        updated_resource = resource_to_update.merge partial_resource

        update_resource_state(name, updated_resource)

        json_response 200, updated_resource
      end

      private

      def find_resource(name, key)
        resource_state(name).detect { |resource| resource['key'] == key }
      end

      def update_resource_state(name, updated_resource)
        updated_resources = resource_state(name).map do |resource|
          resource['key'] == updated_resource['key'] ? updated_resource : resource
        end

        set_resource_state(name, updated_resources)
      end
    end
    # rubocop:enable Metrics/BlockLength

    class_methods do
      def listen_on_index(name, version)
        get "/#{version}/#{name}" do
          on_index_action(name, version)
        end
      end

      def listen_on_show(name, version)
        get "/#{version}/#{name}/:key" do
          on_show_action(name, version)
        end
      end

      def listen_on_create(name, version)
        post "/#{version}/#{name}" do
          on_create_action(name, version)
        end
      end

      def listen_on_update(name, version)
        patch "/#{version}/#{name}/:key" do
          on_update_action(name, version)
        end
      end

      def resource(name, version: 'v1', except: [])
        %i[index show create update].each do |action|
          send("listen_on_#{action}", name, version) unless except.include?(action)
        end
      end
    end
  end
end
