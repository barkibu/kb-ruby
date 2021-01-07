require 'spec_helper'

# shared_examples_for 'ActiveModel' do
#   require 'test/unit/assertions'
#   require 'active_model/lint'
#   include Test::Unit::Assertions
#   include ActiveModel::Lint::Tests

#   before do
#     @model = active_model_instance
#   end

#   ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/).each do |method|
#     example(method.gsub('_', ' ')) { send method }
#   end
# end

# RSpec.describe KB::PetParent do
#   it_behaves_like 'ActiveModel' do
#     let(:active_model_instance) { subject }
#   end
# end
