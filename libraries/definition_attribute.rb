require File.join(File.dirname(__FILE__), 'definition_attribute_base')

module Ingredients
  class Definition
    class Attribute < AttributeBase
      def set_defaults(configuration)
        configuration.default[name] = default_for configuration
      end

      def value(configuration)
        configuration.config[name]
      end
    end
  end
end
