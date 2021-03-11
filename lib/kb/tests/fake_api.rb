require 'kb/tests/bounded_context/pet_family/pet_parents'
require 'kb/tests/bounded_context/pet_family/pets'

module KB
  module Tests
    class ApiState
      attr_accessor :petparents, :pets, :consultations

      def initialize(petparents: [], pets: [], consultations: [])
        @petparents = petparents
        @pets = pets
        @consultations = consultations
      end

      def to_snapshot
        {
          pets: @pets.clone,
          petparents: @petparents.clone,
          consultations: @consultations.clone
        }
      end
    end

    class FakeApi < Sinatra::Base
      include BoundedContext::PetFamily::Pets
      include BoundedContext::PetFamily::PetParents

      set :state, ApiState.new

      def self.snapshot
        FakeApi.state.to_snapshot
      end

      def self.restore(snapshot)
        set :state, ApiState.new(snapshot)
      end

      def resource_state(name)
        FakeApi.state.send(name)
      end

      def set_resource_state(name, value)
        FakeApi.state.send("#{name}=", value)
      end

      resource :consultations, except: %i[create update destroy]
    end
  end
end
