module KB
  class ClientResolver
    class << self
      def consultation
        call :petfamily, :consultations, :v1
      end

      def admin
        call :petfamily, :admin
      end

      def pet_parent
        call :petfamily, :petparents
      end

      def pet
        call :petfamily, :pets
      end

      def pet_contract
        call :petfamily, :petcontracts
      end

      def breed
        call :petfamily, :breeds
      end

      def plan
        call :petfamily, :plans
      end

      def product
        call :petfamily, :products
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
