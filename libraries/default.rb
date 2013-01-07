#
# Provides a DSL for defining the structure of Chef configuration parameters.
# The main entry point into the DSL is {for_cookbook}, which should be placed in
# your `attributes/default.rb` file.
#
# @author David P. Kleinschmidt
#
module Ingredients

  #
  # Gets all top-level configuration classes.
  #
  # @return [Mash{String, Symbol => Class}] All top-level configuration classes,
  #         indexed by name.
  #
  def self.configurations
    return @configurations if instance_variable_defined? :@configurations
    @configurations = Mash.new
  end

  #
  # Creates or opens the top-level configuration class for a cookbook and
  # defines its attributes. The configuration class is an anonymous subclass of
  # {Configuration::Root}). The block is `class_eval`'d inside the class, where
  # all the methods of {Dsl} are available.
  #
  # @return [Configuration::Root] The top-level configuration class for the
  #         cookbook.
  #
  def self.for_cookbook(name, &block)
    if configurations.has_key? name
      ingredient_class = configurations[name]
    else
      ingredient_class = Configuration::Root.create nil, name
      configurations[name] = ingredient_class

      Accessors.__send__ :define_method, name do
        return ingredients[name] if ingredients.has_key? name
        ingredients[name] = ingredient_class.new self
      end
    end

    ingredient_class.add_ingredients &block unless block.nil?
    ingredient_class
  end

  #
  # Sets defaults for all defined cookbooks. This should only be called once per
  # Chef run, from inside the `ingredients` recipe.
  #
  # @param context [#node] The run context in which to set defaults.
  #
  def self.set_defaults(context)
    configurations.each_key {|name| context.send(name).set_defaults}
  end
end
