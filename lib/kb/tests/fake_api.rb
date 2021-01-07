module KB
  module Tests
    class ApiState
      attr_accessor :pet_parents, :consultations

      def initialize(pet_parents: [], consultations: [])
        @pet_parents = pet_parents
        @consultations = consultations
      end

      def to_snapshot
        {
          pet_parents: @pet_parents.clone,
          consultations: @consultations.clone
        }
      end
    end

    class FakeApi < Sinatra::Base
      set :state, ApiState.new

      def pet_parents
        FakeApi.state.pet_parents
      end

      def consultations
        FakeApi.state.consultations
      end

      def self.snapshot
        FakeApi.state.to_snapshot
      end

      def self.restore(snapshot)
        set :state, ApiState.new(snapshot)
      end

      get '/v2/consultations' do
        json_response 200, consultations
      end

      get '/v2/consultations/:key' do
        resource_by_key :consultations, params['key']
      end

      get '/v1/petparents' do
        json_response 200, pet_parents
      end

      get '/v1/petparents/:key' do
        resource_by_key :pet_parents, params['key']
      end

      patch '/v1/petparents/:key' do
        updated_pet_parent = pet_parents.detect { |resource| resource['key'] == params['key'] }

        return json_response 404, {} if updated_pet_parent.nil?

        partial_pet_parent = JSON.parse(request.body.read)
        updated_pet_parent = updated_pet_parent.merge partial_pet_parent
        FakeApi.state.pet_parents = pet_parents.map do |resource|
          resource['key'] == params['key'] ? updated_pet_parent : resource
        end
        json_response 200, updated_pet_parent
      end

      post '/v1/petparents' do
        pet_parent = JSON.parse(request.body.read)
        pet_parent = pet_parent.merge 'key' => SecureRandom.uuid
        FakeApi.state.pet_parents << pet_parent
        json_response 201, pet_parent
      end

      private

      def resource_by_key(resource, key)
        entity = FakeApi.state.public_send(resource).detect { |item| item['key'] == key }
        return json_response 404, {} if entity.nil?

        json_response 200, entity
      end

      def json_response(response_code, body_content)
        content_type :json
        status response_code
        body body_content.to_json
      end
    end
  end
end
