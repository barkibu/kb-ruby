module Inspectionable
  def inspect
    attr_list = attributes.map do |key, value|
      value_str = if value.is_a? ActiveModel::Model
                    "#<#{value.class}: #{format '%<id>#018x', id: value.object_id << 1}>"
                  else
                    value.inspect
                  end
      "#{key}: #{value_str}"
    end.join ', '
    "#<#{self.class}: #{format '%<id>#018x', id: object_id << 1} #{attr_list}>"
  end
end
