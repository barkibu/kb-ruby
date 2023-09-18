require 'kb/fake/bounded_context/rest_resource'
require 'kb/fake/bounded_context/paginable'

module BoundedContext
  module PetFamily
    module PetContracts
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      included do
        include RestResource
        include Paginable

        get '/v1/petcontracts/contractnumber/:contract_number' do
          resource = resource_state(:petcontracts).detect do |contract|
            contract['contractNumber'] == params['contract_number']
          end
          return json_response 404, {} if resource.nil?

          json_response 200, resource
        end

        get '/v1/petcontracts/search' do
          return json_response 400, {} unless params['chip']

          pet_by_chip = resource_state(:pets).detect do |pet|
            pet['chip'] == params['chip']
          end
          return json_response 200, paginate([]) if pet_by_chip.nil?

          contracts = resource_state(:petcontracts).select do |contract|
            contract['petKey'] == pet_by_chip['key']
          end

          json_response 200, paginate(contracts)
        end

        resource :petcontracts, except: %i[index destroy]
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
