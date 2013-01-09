require 'forwardable'

module Ingredients
  class Definition
    class CollectionBase < Definition
      extend Forwardable

      class << self
        attr_accessor :collection_class
      end

      attr_reader :item_class
      def_delegators :item_class, :add_ingredients
      def_delegators 'self.class', :collection_class

      def initialize(configuration_class, name, options={})
        super configuration_class, name, options
        @item_class = collection_class.create name
      end
    end
  end
end
