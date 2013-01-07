require File.join(File.dirname(__FILE__), 'definition_attribute_base')

module Ingredients
  class Definition
    class SearchItemAttribute < AttributeBase
      def set_defaults(configuration)
      end

      def value(configuration)
        configuration.config.fetch name, default_for(configuration)
      end
    end
  end
end
