require 'forwardable'
require File.join(File.dirname(__FILE__), 'dsl')
require File.join(File.dirname(__FILE__), 'accessor')

#
# Copyright 2012, David P. Kleinschmidt
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

module Ingredients
  class Configuration
    extend Dsl, Forwardable

    class << self
      attr_accessor :configuration_name
      attr_reader :data_bag_id, :data_bag_item_id
      alias_method :add_ingredients, :class_eval
    end
    attr_reader :parent

    def_delegators 'self.class', :configuration_name, :data_bag_id,
                   :data_bag_item_id, :ingredient_definitions
    def_delegators :parent, :node

    def self.add_definition(class_, name, options={}, &block)
      if ingredient_definitions.has_key? name
        ingredient = ingredient_definitions[name]
        puts "OPENING #{ingredient.class} #{name.inspect} IN #{configuration_name.inspect}"
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
        puts "CREATING NEW #{class_} #{name.inspect} IN #{configuration_name.inspect}"
        ingredient_definitions[ingredient.name] = ingredient
        define_method name do
          ingredient.get self
        end
      end
      ingredient.add_ingredients &block unless block.nil?
    end

    def self.create(configuration_parent, name)
      Class.new(self).tap do |configuration|
        configuration.configuration_name = name
      end
    end

    def self.ingredient_definitions
      if instance_variable_defined? :@ingredient_definitions
        return @ingredient_definitions
      end
      @ingredient_definitions = {}
    end

    def self.to_s
      "<#{configuration_name}".tap do |string|
        ingredient_definitions.each_key do |name|
          string << " #{name}"
        end
        string << '>'
      end
    end

    def initialize(parent)
      @parent = parent
    end

    def path
      return @path if instance_variable_defined? :@path
      @path = parent.path + path_components
    end

    def path_components
      [configuration_name]
    end

    def set_defaults
      ingredient_definitions.each do |name, ingredient_definition|
        ingredient_definition.set_defaults self
      end
    end

    def to_s
      "<#{configuration_name}".tap do |string|
        ingredient_definitions.each do |name, ingredient_definition|
          string << " #{name}=#{ingredient_definition.get(self).inspect}"
        end
        string << '>'
      end
    end
  end
end
