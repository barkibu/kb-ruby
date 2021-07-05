require 'kb/fake/bounded_context/rest_resource'

module BoundedContext
  module PetFamily
    module Breeds
      extend ActiveSupport::Concern

      included do
        include RestResource

        listen_on_index :breeds, :v1
      end
    end
  end
end
