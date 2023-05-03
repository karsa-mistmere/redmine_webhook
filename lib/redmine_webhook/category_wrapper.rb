module RedmineWebhook
  class CategoryWrapper
    def initialize(category)
      @category = category
    end

    def to_hash
      {
        :id => @category.id,
        :name => @category.name,
      }
    end
  end
end
