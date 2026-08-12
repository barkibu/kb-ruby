require 'kb/fake/bounded_context/pet_family/breeds'
require 'kb/fake/bounded_context/pet_family/pet_parents'
require 'kb/fake/bounded_context/pet_family/pets'
require 'kb/fake/bounded_context/pet_family/products'
require 'kb/fake/bounded_context/pet_family/pet_contracts'

module KB
  module Fake
    class ApiState
      attr_accessor :petparents, :pets, :consultations, :petcontracts, :plans, :breeds, :products, :referrals

      # rubocop:disable Metrics/ParameterLists
      def initialize(petparents: [], pets: [], consultations: [], petcontracts: [], plans: [], breeds: [],
                     products: [], referrals: [])
        @petparents = petparents
        @pets = pets
        @consultations = consultations
        @petcontracts = petcontracts
        @plans = plans
        @breeds = breeds
        @products = products
        @referrals = referrals
      end
      # rubocop:enable Metrics/ParameterLists

      def to_snapshot
        {
          pets: @pets.clone,
          petparents: @petparents.clone,
          consultations: @consultations.clone,
          petcontracts: @petcontracts.clone,
          plans: @plans.clone,
          breeds: @breeds.clone,
          products: @products.clone,
          referrals: @referrals.clone
        }
      end
    end

    class Api < Sinatra::Base
      include BoundedContext::PetFamily::Breeds
      include BoundedContext::PetFamily::Pets
      include BoundedContext::PetFamily::PetParents
      include BoundedContext::PetFamily::PetContracts
      include BoundedContext::PetFamily::Products

      # Sinatra >= 4.1 ships Rack::Protection::HostAuthorization, which authorizes
      # on the Host header and, when it infers a development environment, only
      # permits localhost-style hosts — rejecting requests addressed to the
      # stubbed KB host with "403 Host not permitted". Permitting specific hosts
      # on the consumer side is no fix either: with the net_http adapter WebMock
      # intercepts before Net::HTTP adds the Host header, so the header is absent
      # and can never match a permitted list. An empty list disables the check;
      # it guards against DNS rebinding, which cannot apply to an in-process fake.
      set :host_authorization, permitted_hosts: []

      set :state, ApiState.new

      def self.snapshot
        Api.state.to_snapshot
      end

      def self.restore(snapshot)
        set :state, ApiState.new(**snapshot)
      end

      def resource_state(name)
        Api.state.send(name)
      end

      def set_resource_state(name, value)
        Api.state.send("#{name}=", value)
      end

      resource :consultations, except: %i[create update destroy]

      resource :plans, except: %i[show create update destroy]
    end
  end
end
