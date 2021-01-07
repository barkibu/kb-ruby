module Type
  class ArrayOfSymptomsType < ActiveModel::Type::Value
    SYMPTOM_KEYS = KB::Symptom.attribute_types.keys.map(&:to_sym)

    def cast(value)
      (value || []).map do |v|
        return v if v.is_a? KB::Symptom

        KB::Symptom.new v.symbolize_keys.slice(*SYMPTOM_KEYS)
      end
    end
  end
end
