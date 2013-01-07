require 'forwardable'
require File.join(File.dirname(__FILE__), 'dsl')
require File.join(File.dirname(__FILE__), 'accessors')

module Ingredients

  #
  # Superclass for all objects returned by the {Accessors}; these are the
  # objects through which you access your configuration parameters.
  #
  # The first layer of subclasses below {Configuration} is specialized for
  # retrieving parameters from different locations, whether it's a namespace, a
  # data bag, or search results. Subclasses must respond to `config`,
  # `data_bag_item`, and `default`.
  #
  # The bottom layer of subclasses are specialized for your service and defined
  # with {for_cookbook} and other DSL methods.
  #
  class Configuration
    extend Dsl, Forwardable
    include Accessors

    class << self
      #
      # The name of the configuration class. This means slightly different
      # things in different contexts; to a {Root}, for instance, this is the
      # name of your cookbook; to a {Namespace}, this is the namespace name.
      #
      # @return [String] The name of the configuration class.
      #
      attr_accessor :configuration_name

      #
      # Adds the DSL definitions supplied in a block to the current class.
      #
      alias_method :add_ingredients, :class_eval
    end

    #
    # Access this configuration's logical parent. For {Root}s, this is the Chef
    # context object; for everything else, this is the enclosing configuration.
    #
    # @return [#node] This configuration's logical parent.
    #
    attr_reader :parent

    def_delegators 'self.class', :configuration_name, :definitions
    def_delegators :parent, :node

    #
    # Adds a {Definition} to this {Configuration} class or opens a definition
    # that has already been added to this configuration class. This should only
    # be called through the methods in {Dsl}.
    #
    # @param [Class] class_ The class of the definition to add. This should be a
    #        subclass of {Definition}.
    # @param [String, Symbol] name The definition's name.
    # @param [Hash] options Options that should be set on the definition.
    # @param [Proc] block Block that will be used to provide inner attributes to
    #        the definition.
    #
    # @return [Definition] The definition that was added or opened.
    #
    # @raise [TypeError] if there is already a definition with this name and its
    #        class is not the same as the new class.
    # @raise [ArgumentError] if there is already a definition with this name,
    #        one of the options has already been provided, and the new value of
    #        the option is not equal to the old value.
    #
    def self.add_definition(class_, name, options={}, &block)
      if definitions.has_key? name
        ingredient = definitions[name]
        unless ingredient.instance_of? class_
          raise TypeError, "Ingredient #{name.inspect} cannot be redefined from #{ingredient.class} to #{class_}."
        end
        options.each do |option, value|
          if ingredient.options.has_key?(option) &&
              ingredient.options[option] != value
            raise ArgumentError, "Ingredient #{name.inspect} option #{option.inspect} cannot be changed from #{ingredient.options[option]} to #{value.inspect}."
          end
          ingredient.options[option] = value
        end
      else
        ingredient = class_.new self, name, options
        definitions[ingredient.name] = ingredient
        define_method name do
          ingredient.get self
        end
      end
      ingredient.add_ingredients &block unless block.nil?
      ingredient
    end

    #
    # Makes a new configuration subclass. This should not be called directly on
    # the {Configuration} base class, but rather on one of the specialized
    # subclasses. It should only be called by {for_cookbook} and the
    # {Definition} constructors.
    #
    # @param [String] name The new subclass's {configuration_name}.
    # @return [Class] An anonymous subclass of this class.
    #
    def self.create(name)
      Class.new(self).tap do |configuration|
        configuration.configuration_name = name
      end
    end

    #
    # A Mash of all the definitions on this configuration class.
    #
    # @return [Mash{String, Symbol => Definition}] All the definitions on this
    #         configuration class, indexed by name.
    #
    def self.definitions
      return @definitions if instance_variable_defined? :@definitions
      @definitions = Mash.new
    end

    #
    # Returns a sane description of this class for error reporting. Do not rely
    # on the format of this string.
    #
    # @return [String] A description of this class.
    #
    def self.to_s
      return @to_s if instance_variable_defined? :@to_s
      @to_s = "<#{configuration_name}".tap do |string|
        definitions.each_key {|name| string << " #{name}"}
        string << '>'
      end
    end

    #
    # Create a new configuration object.
    #
    # @param [#node] parent The new configuration's parent object.
    #
    def initialize(parent)
      @parent = parent
    end

    #
    # Get the full path of keys to follow to get to this configuration.
    #
    # @return [Array<Integer, String, Symbol>] The key path for this
    #         configuration.
    #
    def path
      return @path if instance_variable_defined? :@path
      @path = parent.path + path_components
    end

    #
    # Get only the keys that this configuration contributes to the key path.
    # This excludes the parent's key path.
    #
    # @return [Array<Integer, String, Symbol>] The key path for this
    #         configuration, relative to the parent.
    #
    def path_components
      [configuration_name]
    end

    #
    # Sets defaults recursively on this configuration. This should only be
    # called by {Ingredients.set_defaults} and the {Definition} subclasses.
    #
    # @return [void]
    #
    def set_defaults
      definitions.each {|name, definition| definition.set_defaults self}
    end

    #
    # Returns a sane description of this instance for error reporting. Do not
    # rely on the format of this string.
    #
    # @return [String] A description of this instance.
    #
    def to_s
      return @to_s if instance_variable_defined? :@to_s
      @to_s = "<#{configuration_name}".tap do |string|
        definitions.each do |name, definition|
          string << " #{name}=#{definition.get(self).inspect}"
        end
        string << '>'
      end
    end
  end
end
