require 'spec_helper'

# rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/MultipleExpectations, RSpec/VerifiedDoubles, RSpec/ContextWording
RSpec.describe KB::Concerns::AsKBWrapper do
  include_context 'with Mock ActiveRecord Class'

  let(:kb_model_class) { double 'KB::Resource::class' }
  let(:kb_model_instance) { double 'KB::Resource::instance' }
  let(:kb_model_new_instance) { double 'KB::Resource::instance' }

  let(:model_class) do
    resource_class = kb_model_class
    Class.new(active_record_class) do
      include KB::Concerns::AsKBWrapper

      wrap_kb model: resource_class
    end
  end

  let(:kb_key) { 'Underlying KB Resource Key' }
  let(:instance) { model_class.new(kb_key: kb_key) }

  before do
    allow(kb_model_class).to receive(:find).and_return(kb_model_instance)
  end

  describe '.wrap_kb' do
    context 'underlying kb entity' do
      it 'allow kb_model to be set' do
        instance.kb_model = kb_model_new_instance
        expect(instance.kb_model).to be kb_model_new_instance
      end

      it 'calls :save_underlying_kb_entity! before actually saving the record' do
        expect(instance).to receive(:save_underlying_kb_entity!).ordered
        expect(instance).to receive(:actually_saving).ordered
        instance.save
      end

      describe '#kb_model' do
        it 'calls `find` on the underlying kb entity class' do
          expect(kb_model_class).to receive :find
          instance.kb_model
        end

        it 'serves the cached first fetched underlying kb entity on subsequent requests' do
          expect(kb_model_class).to receive(:find).once.and_return(kb_model_instance)
          instance.kb_model
          instance.kb_model
        end

        it 'returns the KB resource found' do
          expect(instance.kb_model).to be kb_model_instance
        end

        it 'returns a fresh KB resource if not found' do
          expect(kb_model_class).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          allow(kb_model_class).to receive(:new).and_return(kb_model_new_instance)
          expect(instance.kb_model).to be kb_model_new_instance
        end
      end

      describe '#reload' do
        it 'forces the underlying resource stored in the local_attribute to be re-pulled on request' do
          expect(kb_model_class).to receive(:find).twice.and_return(kb_model_instance)
          instance.kb_model
          instance.reload
          instance.kb_model
        end
      end

      describe '#save_underlying_kb_entity!' do
        before do
          allow(kb_model_instance).to receive(:save!).and_return(kb_model_instance)
          allow(kb_model_instance).to receive(:key).and_return kb_key
        end

        it 'calls `save` on the underlying kb resource' do
          expect(kb_model_instance).to receive(:save!).and_return(kb_model_instance)
          instance.save_underlying_kb_entity!
        end

        it 'sets the received kb resource key on the `kb_key` attribute' do
          expect(instance).to receive('kb_key=').with(kb_key)
          instance.save_underlying_kb_entity!
        end
      end

      describe '#kb_find_by' do
        pending 'Should be arranged first'
      end

      describe '#kb_find_by!' do
        let(:params) { { foo: 'bar' } }

        it 'returns whatever non nil kb_find_by returns' do
          allow(model_class).to receive(:kb_find_by).with(params).and_return(kb_model_instance)
          expect(model_class.kb_find_by!(params)).to be kb_model_instance
        end

        it 'raise an ActiveRecord::RecordNotFound  when kb_find_by returns nil' do
          allow(model_class).to receive(:kb_find_by).with(params).and_return nil
          expect { model_class.kb_find_by!(params) }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
# rubocop:enable RSpec/StubbedMock, RSpec/MessageSpies, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups, RSpec/MultipleExpectations, RSpec/VerifiedDoubles, RSpec/ContextWording
