require File.join(File.dirname(__FILE__), 'configuration_ordered_item')
require File.join(File.dirname(__FILE__), 'definition_collection_base')

module Ingredients
  class Definition
    class OrderedCollection < CollectionBase
      self.collection_class = Configuration::OrderedItem

      def set_defaults(configuration)
        get(configuration).each &:set_defaults
      end

      def value(configuration)
        [].tap do |value|
          config = if configuration.config.has_key? name
            configuration.config[name]
          else
            []
          end
          config.count.times do |index|
            value << item_class.new(configuration, index)
          end
        end
      end
    end
  end
end
