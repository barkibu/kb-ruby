require 'kb/fake/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module Products
      extend ActiveSupport::Concern
      include RestResource

      included do
        include RestResource

        resource :products, except: %i[create update destroy]

        def products_filterable_attributes
          [:country]
        end

        def on_products_index(_version)
          return json_response 400, {} if params['country'].nil?

          return json_response 422, {} if ISO3166::Country.search(params['country']).nil?

          json_response 200, filter_resources(:products, params)
        end
      end
    end
  end
end
