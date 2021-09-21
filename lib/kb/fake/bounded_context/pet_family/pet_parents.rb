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
          potential_matches = filter_resources(:petparents,
                                               params.slice('phoneNumber', 'prefixPhoneNumber', 'email', 'key'), :upsert)
          existing_pet_parent = (potential_matches.first if potential_matches.count == 1)

          resource = (existing_pet_parent || { 'key' => SecureRandom.uuid }).merge params

          if existing_pet_parent.present?
            if same_phone_number_but_different_email?(existing_pet_parent, params)
              return json_response 422, { error: 'Unprocessable Entity', message: 'Email can not be overridden' }
            end

            if same_email_but_different_phone_number?(existing_pet_parent, params)
              return json_response 422, { error: 'Unprocessable Entity', message: 'Phone number can not be overridden' }
            end

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

        def same_email_but_different_phone_number?(previous, new)
          (previous['email'] == new['email']) &&
            ((previous['phoneNumber'] != new['phoneNumber']) || (previous['prefixPhoneNumber'] != new['prefixPhoneNumber']))
        end

        def same_phone_number_but_different_email?(previous, new)
          (previous['phoneNumber'] == new['phoneNumber']) && (previous['prefixPhoneNumber'] == new['prefixPhoneNumber']) &&
            (previous['email'] != new['email'])
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
