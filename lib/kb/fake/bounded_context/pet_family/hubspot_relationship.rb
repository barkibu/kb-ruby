require 'kb/fake/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module HubspotRelationship
      extend ActiveSupport::Concern

      included do
        include RestResource

        get '/v1/hubspot/:model/:key/relationship' do
          resource_by_key(:hubspot_relationship, params['key'])
        end
      end
    end
  end
end
