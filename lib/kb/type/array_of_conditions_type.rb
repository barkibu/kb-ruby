module Type
  class ArrayOfConditionsType < ActiveModel::Type::Value
    CONDITION_KEYS = KB::Condition.attribute_types.keys.map(&:to_sym)

    def cast(value)
      (value || []).map do |v|
        return v if v.is_a? KB::Condition

        KB::Condition.new v.symbolize_keys.slice(*CONDITION_KEYS)
      end
    end
  end
end
