module BoundedContext
  module Paginable
    extend ActiveSupport::Concern

    included do
      def paginate(list)
        list = list.to_a
        page = params.fetch('page', 1).to_i
        page_size = params.fetch('size', 10).to_i
        offset = (page - 1) * page_size

        { total: list.size,
          page: page,
          elements: list[offset, page_size] }
      end
    end
  end
end
