require 'kb/fake/bounded_context/pet_family/pet_parents'
require 'kb/fake/bounded_context/pet_family/pets'
require 'kb/fake/bounded_context/pet_family/pet_contracts'

module KB
  module Fake
    class ApiState
      attr_accessor :petparents, :pets, :consultations, :petcontracts, :plans

      def initialize(petparents: [], pets: [], consultations: [], petcontracts: [], plans: [])
        @petparents = petparents
        @pets = pets
        @consultations = consultations
        @petcontracts = petcontracts
        @plans = plans
      end

      def to_snapshot
        {
          pets: @pets.clone,
          petparents: @petparents.clone,
          consultations: @consultations.clone,
          petcontracts: @petcontracts.clone,
          plans: @plans.clone
        }
      end
    end

    class Api < Sinatra::Base
      include BoundedContext::PetFamily::Pets
      include BoundedContext::PetFamily::PetParents
      include BoundedContext::PetFamily::PetContracts

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

      resource :consultations, version: 'v2', except: %i[create update destroy]

      resource :plans, except: %i[show create update destroy]
    end
  end
end
