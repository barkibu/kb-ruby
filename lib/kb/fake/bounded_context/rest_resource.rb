# rubocop:disable Metrics/BlockLength
module BoundedContext
  module RestResource
    extend ActiveSupport::Concern

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

      def on_index_action(name, version)
        return send("on_#{name}_index", version) if respond_to? "on_#{name}_index"

        json_response 200, filter_resources(name, params)
      end

      def filter_resources(name, filters)
        resource_state(name).select do |item|
          item['deleted_at'].blank? && filters.slice(*filterable_attributes(name)).reduce(true) do |sum, (key, value)|
            sum && (value.blank? \
                    || (item.fetch(key, '') || '').downcase.include?(value.downcase))
          end
        end
      end

      def filterable_attributes(name)
        try("#{name}_filterable_attributes") || []
      end

      def on_show_action(name, version)
        return send("on_#{name}_show", version) if respond_to? "on_#{name}_show"

        resource_by_key name, params['key']
      end

      def on_create_action(name, version)
        return send("on_#{name}_create", version) if respond_to? "on_#{name}_create"

        resource = JSON.parse(request.body.read)
        resource = resource.merge 'key' => SecureRandom.uuid
        resource_state(name) << resource
        json_response 201, resource
      end

      def on_update_action(name, version)
        return send("on_#{name}_update", version) if respond_to? "on_#{name}_update"

        resource_to_update = find_resource name, params['key']

        return json_response 404, {} if resource_to_update.nil?

        partial_resource = JSON.parse(request.body.read)
        updated_resource = resource_to_update.merge partial_resource

        update_resource_state(name, updated_resource)

        json_response 200, updated_resource
      end

      def on_destroy_action(name, version)
        return send("on_#{name}_destroy", version) if respond_to? "on_#{name}_destroy"

        resource_to_delete = find_resource name, params['key']
        resource_to_delete['deleted_at'] = DateTime.now

        update_resource_state(name, resource_to_delete)

        json_response 204, nil
      end

      private

      def find_resource(name, key)
        resource_state(name).detect do |resource|
          (resource['key'] == key) && resource['deleted_at'].blank?
        end
      end

      def update_resource_state(name, updated_resource)
        updated_resources = resource_state(name).map do |resource|
          resource['key'] == updated_resource['key'] ? updated_resource : resource
        end

        set_resource_state(name, updated_resources)
      end
    end

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

      def listen_on_destroy(name, version)
        delete "/#{version}/#{name}/:key" do
          on_destroy_action(name, version)
        end
      end

      def resource(name, version: 'v1', except: [])
        %i[index show create update destroy].each do |action|
          send("listen_on_#{action}", name, version) unless except.include?(action)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
