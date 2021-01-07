module KB
  class ClientResolver
    class << self
      def consultation
        call '', :consultations, :v2
      end

      def pet_parent
        call :petfamily, :petparents
      end

      def pet
        call :petfamily, :pets
      end

      def call(*args, &block)
        new(*args, &block).call
      end
    end

    attr_reader :template, :bounded_context, :entity, :version

    def initialize(bounded_context, entity, version = 'v1', template: ENV['KB_API_URL_TEMPLATE'])
      @bounded_context = bounded_context
      @entity = entity
      @version = version
      @template = template
    end

    def call
      KB::Client.new base_url
    end

    def base_url
      format(template, bounded_context: bounded_context, entity: entity, version: version).gsub('..', '.')
    end
  end
end
