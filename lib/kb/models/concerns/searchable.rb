module KB
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def search(filters)
        response = kb_client.request('search', filters: filters).symbolize_keys
        elements = response[:elements].map { |contract| from_api(contract) }
        KB::SearchResult.new(**response.merge(elements: elements))
      rescue Faraday::Error => e
        raise KB::Error.from_faraday(e)
      end
    end
  end
end
