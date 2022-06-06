module KB
  module HubspotRelationable
    extend ActiveSupport::Concern

    included do
      class_attribute :hubspot_model_name
    end

    module ClassMethods
      def hubspot_model(model)
        self.hubspot_model_name = model
      end
    end

    def hubspot
      @hubspot ||= KB::Hubspot.relationship(hubspot_model_name, key)
    end

    def hubspot_id
      hubspot.hubspot_id
    end
  end
end
