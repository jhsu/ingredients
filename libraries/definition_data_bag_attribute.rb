require File.join(File.dirname(__FILE__), 'definition_attribute_base')

module Ingredients
  class Definition
    class DataBagAttribute < AttributeBase
      def set_defaults(configuration)
      end

      def value(configuration)
        configuration.data_bag_item.fetch name, default_for(configuration)
      end
    end
  end
end
