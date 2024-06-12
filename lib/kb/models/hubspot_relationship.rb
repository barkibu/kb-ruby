module KB
  class HubspotRelationship < BaseModel
    include Queryable

    kb_api :hubspot

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[kb_key hubspot_id].freeze
    DATE_FIELDS = %i[last_updated_at].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    define_attributes STRING_FIELDS, :string
    define_attributes DATE_FIELDS, :date

    def self.find(model, model_key)
      response = kb_client.request("#{model}/#{model_key}/relationship")
      new(attributes_from_response(response))
    rescue Faraday::Error => e
      raise KB::Error.from_faraday(e)
    end
  end
end
