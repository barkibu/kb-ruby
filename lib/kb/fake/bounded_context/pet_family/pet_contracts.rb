require 'kb/fake/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module PetContracts
      extend ActiveSupport::Concern

      included do
        include RestResource

        get '/v1/petcontracts/contractnumber/:contract_number' do
          resource = resource_state(:petcontracts).detect do |contract|
            contract['contractNumber'] == params['contract_number']
          end
          return json_response 404, {} if resource.nil?

          json_response 200, resource
        end

        resource :petcontracts, except: %i[index destroy]
      end
    end
  end
end
