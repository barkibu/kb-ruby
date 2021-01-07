module Type
  class ArrayOfStringsType < ActiveModel::Type::Value
    def cast(values)
      return [] if values.blank?

      values.map(&:to_s)
    end
  end
end
