module KB
  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors.add(attribute, :taken) if already_registered?(record, attribute, value)
    end

    private

    def already_registered?(record, attribute, value)
      filters = scope_filters(record, attribute, value).merge({ "#{attribute}": value })
      all_records(record, filters).any? do |kb_record|
        kb_record.key != record.kb_key
      end
    end

    def all_records(record, filters)
      record.kb_model.class.all(filters)
    end

    def scope_filters(record, _attribute, _value)
      Array.wrap(options[:scope]).to_h do |scope_attribute|
        [scope_attribute, record.send(scope_attribute)]
      end
    end
  end
end
