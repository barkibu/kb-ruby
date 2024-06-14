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

        def on_petparents_show(_version)
          pet_parent = pet_parent_by_key(params).dup
          return json_response 404, {} if pet_parent.nil?

          pet_parent['iban_last4'] = pet_parent.delete('iban')&.chars&.last(4)&.join

          json_response 200, pet_parent
        end

        get '/v1/petparents/:key/pets' do
          json_response 200, pets_by_pet_parent_key(params['key'])
        end

        get '/v1/petparents/:key/contracts' do
          pet_keys = pets_by_pet_parent_key(params['key']).map { |pet| pet['key'] }
          contracts = resource_state(:petcontracts).select { |contract| pet_keys.include? contract['petKey'] }

          json_response 200, contracts
        end

        get '/v1/petparents/:key/referrals' do
          json_response 200, referrals_by_pet_parent_key(params['key'])
        end

        get '/v1/petparents/:key/referrers' do
          json_response 200, referrers_by_pet_parent_key(params['key'])
        end

        post '/v1/petparents/:key/referrals' do
          resource = JSON.parse(request.body.read)
          resource = resource.merge 'key' => SecureRandom.uuid
          resource = resource.merge 'referralKey' => params['key']
          resource_state(:referrals) << resource
          json_response 201, resource
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

        get '/v1/petparents/:key/iban' do
          pet_parent = pet_parent_by_key(params)
          return json_response 404, {} if pet_parent.blank?

          json_response 200, { iban: pet_parent['iban'] }
        end

        put '/v1/petparents/:key/iban' do
          pet_parent = pet_parent_by_key(params)
          return json_response 404, {} if pet_parent.blank?

          body = JSON.parse(request.body.read)

          updated_pet_parent = pet_parent.merge body.slice('iban')
          update_resource_state(:petparents, updated_pet_parent)

          json_response 200, { iban: updated_pet_parent['iban'] }
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

        def referrals_by_pet_parent_key(key)
          resource_state(:referrals).select { |resource| resource['referralKey'] == key }
        end

        def referrers_by_pet_parent_key(key)
          pet_keys = resource_state(:pets).select { |pet| pet['petParentKey'] == key }.map { |pet| pet['key'] }
          resource_state(:referrals).select { |referral| pet_keys.include? referral['referredKey'] }
        end

        def same_email_but_different_phone_number?(previous, new)
          (previous['email'] == new['email']) &&
            ((previous['phoneNumber'] != new['phoneNumber']) ||
             (previous['prefixPhoneNumber'] != new['prefixPhoneNumber']))
        end

        def same_phone_number_but_different_email?(previous, new_resource)
          return false unless new_resource.key?('email')

          (previous['phoneNumber'] == new_resource['phoneNumber']) &&
            (previous['prefixPhoneNumber'] == new_resource['prefixPhoneNumber']) &&
            (previous['email'] != new_resource['email'])
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
