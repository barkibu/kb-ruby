require 'kb/tests/bounded_context/rest_resource'
require 'date'

module BoundedContext
  module PetFamily
    module Pets
      extend ActiveSupport::Concern
      include RestResource

      included do
        include RestResource

        resource :pets

        def pets_filterable_attributes
          KB::Pet::FIELDS.map { |k| k.to_s.camelize(:lower) }
        end

        def on_create_action(name, _version)
          resource = JSON.parse(request.body.read)
          resource['ageCategory'] = stage(resource['birthDate'], resource['species'])
          resource = resource.merge 'key' => SecureRandom.uuid
          resource_state(name) << resource
          json_response 201, resource
        end

        def on_update_action(name, _version)
          resource_to_update = find_resource name, params['key']

          return json_response 404, {} if resource_to_update.nil?

          partial_resource = JSON.parse(request.body.read)
          partial_resource['ageCategory'] = stage(partial_resource['birthDate'], resource_to_update['species'])
          updated_resource = resource_to_update.merge partial_resource

          update_resource_state(name, updated_resource)

          json_response 200, updated_resource
        end
      end

      def stage(birthdate, species)
        return nil if birthdate.nil?

        case ((Time.zone.now - Time.zone.parse(birthdate)) / 1.month).to_i
        when 0..11
          species == 'cat' ? 'kitten' : 'puppy'
        when 12..99
          'adult'
        else
          'senior'
        end
      end
    end
  end
end
