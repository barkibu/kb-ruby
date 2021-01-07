module KB
  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors.add(attribute, :taken) if already_registered?(record, attribute, value)
    end

    private

    def already_registered?(record, attribute, value)
      all_records.any? do |kb_record|
        kb_record.key != record.send(record_kb_key) && kb_record.send(attribute) == value
      end
    end

    def all_records
      KB::PetParent.all
    end

    def record_kb_key
      :kb_key
    end
  end
end
