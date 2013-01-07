require File.join(File.dirname(__FILE__), 'configuration_namespace')
require File.join(File.dirname(__FILE__), 'definition_collection_base')

module Ingredients
  class Definition
    class Namespace < CollectionBase
      self.collection_class = Configuration::Namespace

      def optional
        return @optional if instance_variable_defined? :@optional
        @optional = options.fetch(:optional, false)
      end

      def set_defaults(configuration)
        value = get(configuration)
        value.set_defaults unless value.nil?
      end

      def value(configuration)
        unless optional && (configuration.config.nil? ||
                            !configuration.config.has_key?(name))
          item_class.new configuration
        end
      end
    end
  end
end
