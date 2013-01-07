module Ingredients
  class Definition
    attr_reader :configuration_class, :name, :options

    def add_ingredients(&block)
    end

    def get(configuration)
      if configuration.ingredients.has_key? name
        return configuration.ingredients[name]
      end
      configuration.ingredients[name] = value configuration
    end

    def initialize(configuration_class, name, options)
      @configuration_class = configuration_class
      @name = name.to_sym
      @options = Mash.new options
    end
  end
end
