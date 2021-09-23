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
          existing_pet_parent = pet_parent_by_key(params) || pet_parent_by_email(params) || pet_parent_by_phone(params)
          resource = (existing_pet_parent || { 'key' => SecureRandom.uuid }).merge params

          if existing_pet_parent.present?
            if same_phone_number_but_different_email?(existing_pet_parent, params)
              return json_response 422, { error: 'Unprocessable Entity', message: 'Email can not be overridden' }
            end

            if same_email_but_different_phone_number?(existing_pet_parent, params)
              previous_pet_parent_by_phone = pet_parent_by_phone(params)
              if previous_pet_parent_by_phone.present?
                return json_response 409,
                                     { error: 'ConflictError',
                                       message: 'Duplicated pet parent: same partner, phoneNumber \
                                                and phoneNumberPrefix' }
              end
            end

            update_resource_state(:petparents, resource)
          else
            resource_state(:petparents) << resource
          end

          json_response 200, resource
        end

        private

        def pet_parent_by_key(params)
          find_resource(:petparents, params['key']) if params['key']
        end

        def pet_parent_by_phone(params)
          matches_by_phone = (if params['phoneNumber']
                                filter_resources(:petparents,
                                                 params.slice('phoneNumber',
                                                              'prefixPhoneNumber'))
                              end)
          matches_by_phone.first if matches_by_phone&.count == 1
        end

        def pet_parent_by_email(params)
          matches_by_email = (filter_resources(:petparents, params.slice('email')) if params['email'])
          matches_by_email.first if matches_by_email&.count == 1
        end

        def pets_by_pet_parent_key(key)
          resource_state(:pets).select { |pet| pet['petParentKey'] == key }
        end

        def same_email_but_different_phone_number?(previous, new)
          (previous['email'] == new['email']) &&
            ((previous['phoneNumber'] != new['phoneNumber']) ||
             (previous['prefixPhoneNumber'] != new['prefixPhoneNumber']))
        end

        def same_phone_number_but_different_email?(previous, new)
          (previous['phoneNumber'] == new['phoneNumber']) &&
            (previous['prefixPhoneNumber'] == new['prefixPhoneNumber']) &&
            (previous['email'] != new['email'])
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
