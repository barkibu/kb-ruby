module KB
  class Referral < BaseModel
    include Queryable

    kb_api :pet_parent

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key referral_key referred_key type].freeze
    DATE_FIELDS = %i[joined_at].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    DATE_FIELDS.each do |field|
      attribute field, :date
    end

    def self.create(pet_parent_key, attributes)
      response = kb_client.request("#{pet_parent_key}/referrals", filters: attributes, method: :post)
      new(attributes_from_response(response))
    rescue Faraday::Error => e
      raise KB::Error.from_faraday(e)
    end
  end
end
