require 'kb/tests/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module PetContracts
      extend ActiveSupport::Concern

      included do
        include RestResource

        resource :petcontracts, except: %i[index]

        def petcontracts_filterable_attributes
          KB::PetContract::FIELDS.map { |k| k.to_s.camelize(:lower) }
        end

        # TODO: Add basic exceptions for PetKey missing etc
      end
    end
  end
end
