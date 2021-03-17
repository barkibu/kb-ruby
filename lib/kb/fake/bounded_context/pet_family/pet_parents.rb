require 'kb/fake/bounded_context/rest_resource'

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

        private

        def pets_by_pet_parent_key(key)
          resource_state(:pets).select { |pet| pet['petParentKey'] == key }
        end
      end
    end
  end
end
