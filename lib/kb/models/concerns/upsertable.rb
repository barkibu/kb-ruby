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
        raise_custom_errors(e.response[:body]) if [409, 422].include? e.response[:status]

        raise KB::Error.new(e.response[:status], e.response[:body], e)
      end

      def raise_custom_errors(body)
        begin
          json_body = JSON.parse(body)
        rescue JSON::ParserError
          json_body = ''
        end

        return unless json_body.is_a?(Hash)

        raise KB::UnprocessableEntityError, json_body['message'] if json_body['error'] == 'Unprocessable Entity'
        raise KB::ConflictError, json_body['message'] if json_body['error'] == 'Conflict'
      end
    end
  end
end
