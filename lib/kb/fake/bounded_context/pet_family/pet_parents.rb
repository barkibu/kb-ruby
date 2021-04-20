require 'kb/fake/bounded_context/rest_resource'
# rubocop:disable Metrics/BlockLength

module BoundedContext
  module PetFamily
    module PetParents
      extend ActiveSupport::Concern

      included do
        include RestResource

        resource :petparents

        def petparents_filterable_attributes
          KB::PetParent::FIELDS.map { |k| k.to_s.camelize(:lower) }
        end

        get '/v1/petparents/:key/pets' do
          json_response 200, pets_by_pet_parent_key(params['key'])
        end

        get '/v1/petparents/:key/contracts' do
          pet_keys = pets_by_pet_parent_key(params['key']).map { |pet| pet['key'] }
          contracts = resource_state(:petcontracts).select { |contract| pet_keys.include? contract['petKey'] }

          json_response 200, contracts
        end

        put '/v1/petparents' do
          params = JSON.parse(request.body.read)
          potential_matches = filter_resources(:petparents, params.slice('phoneNumber', 'prefixPhoneNumber'))
          existing_pet_parent = (potential_matches.first if potential_matches.count == 1)

          resource = (existing_pet_parent || { 'key' => SecureRandom.uuid }).merge params

          if existing_pet_parent.present?
            update_resource_state(:petparents, resource)
          else
            resource_state(:petparents) << resource
          end

          json_response 200, resource
        end

        private

        def pets_by_pet_parent_key(key)
          resource_state(:pets).select { |pet| pet['petParentKey'] == key }
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
