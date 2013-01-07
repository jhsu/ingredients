require File.join(File.dirname(__FILE__), 'definition_attribute')

module Ingredients
  class Definition
    class OrderedItemAttribute < Attribute
      def set_defaults(configuration)
        unless configuration.default.has_key? name
          configuration.default[name] = default_for configuration
        end
      end
    end
  end
end
