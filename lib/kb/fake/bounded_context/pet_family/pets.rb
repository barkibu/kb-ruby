require 'kb/fake/bounded_context/rest_resource'
require 'date'
# rubocop:disable Metrics/BlockLength

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

        def on_pets_create(_version)
          resource = JSON.parse(request.body.read)
          resource['ageCategory'] = stage(resource['birthDate'], resource['species'])
          resource = resource.merge 'key' => SecureRandom.uuid
          resource_state(:pets) << resource
          json_response 201, resource
        end

        def on_pets_update(_version)
          resource_to_update = find_resource :pets, params['key']

          return json_response 404, {} if resource_to_update.nil?

          partial_resource = JSON.parse(request.body.read)
          partial_resource['ageCategory'] = stage(partial_resource['birthDate'], resource_to_update['species'])
          updated_resource = resource_to_update.merge partial_resource

          update_resource_state(:pets, updated_resource)

          json_response 200, updated_resource
        end

        get '/v1/pets/:key/contracts' do
          contracts = resource_state(:petcontracts).select { |contract| contract['petKey'] == params['key'] }

          json_response 200, contracts
        end

        put '/v1/pets' do
          params = JSON.parse(request.body.read)
          pet_parent = find_resource(:petparents, params['petParentKey'])

          return json_response 422, {} if pet_parent.nil?

          potential_matches = filter_resources(:pets, params.slice('name', 'petParentKey'))
          existing_pet = (potential_matches.first if potential_matches.count == 1)

          resource = (existing_pet || { 'key' => SecureRandom.uuid }).merge params

          if existing_pet.present?
            update_resource_state(:pets, resource)
          else
            resource_state(:pets) << resource
          end

          json_response 200, resource
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
# rubocop:enable Metrics/BlockLength
