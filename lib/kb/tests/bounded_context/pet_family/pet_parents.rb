require 'kb/tests/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module PetParents
      extend ActiveSupport::Concern

      included do
        include RestResource

        resource :petparents

        get '/v1/petparents/:key/pets' do
          pets = resource_state(:pets).select { |pet| pet['petParentKey'] == params['key'] }

          json_response 200, pets
        end
      end
    end
  end
end
