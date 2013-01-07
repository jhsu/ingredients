require File.join(File.dirname(__FILE__), 'configuration_named_item')
require File.join(File.dirname(__FILE__), 'definition_collection_base')

module Ingredients
  class Definition
    class NamedCollection < CollectionBase
      self.collection_class = Configuration::NamedItem

      def default
        return @default if instance_variable_defined? :@default
        @default = options[:default]
      end

      def set_defaults(configuration)
        get(configuration).each_value &:set_defaults
      end

      def value(configuration)
        Mash.new.tap do |value|
          config = if configuration.config.nil? ||
              !configuration.config.has_key?(name)
            Mash.new
          else
            configuration.config[name]
          end
          if config.empty? && !default.nil?
            value[default] = item_class.new configuration, default
          else
            config.each_key do |name|
              value[name] = item_class.new configuration, name
            end
          end
        end
      end
    end
  end
end
