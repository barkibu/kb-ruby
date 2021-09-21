module KB
  module Upsertable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def upsert(attributes)
        from_api kb_client.upsert(attributes)
      rescue Faraday::Error => e
        if e.response[:status] = 422
          begin
            json_body = JSON.parse(e.response[:body])
          rescue JSON::ParserError
            json_body = ''
          end

          if json_body.is_a?(Hash) && json_body['error'] == 'Unprocessable Entity'
            raise KB::UnprocessableEntityError, json_body['message']
          end
        end

        raise KB::Error.new(e.response[:status], e.response[:body], e)
      end
    end
  end
end
