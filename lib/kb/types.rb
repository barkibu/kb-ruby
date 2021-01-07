require 'kb/type/array_of_conditions_type'
require 'kb/type/array_of_symptoms_type'

ActiveModel::Type.register :array_of_symptoms, Type::ArrayOfSymptomsType
ActiveModel::Type.register :array_of_conditions, Type::ArrayOfConditionsType
