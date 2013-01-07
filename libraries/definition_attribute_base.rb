module Ingredients
  class Definition
    class AttributeBase < Definition
      def default
        return @default if instance_variable_defined? :@default
        @default = options.fetch :default, nil
      end

      def default_for(configuration)
        default.is_a?(Proc) ? configuration.instance_eval(&default) : default
      end
    end
  end
end
