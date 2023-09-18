module KB
  class SearchResult
    attr_reader :elements, :total, :page

    def initialize(elements:, total:, page:)
      @elements = elements
      @total = total
      @page = page
    end
  end
end
