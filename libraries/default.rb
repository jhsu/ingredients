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
  def self.configurations
    return @configurations if instance_variable_defined? :@configurations
    @configurations = Mash.new
  end

  def self.include_classes
    return @include_classes if instance_variable_defined? :@include_classes
    @include_classes = [
      Chef::Provider,
      Chef::Recipe,
      Chef::Resource,
      Chef::RunContext,
      Erubis::Context,
      Ingredients::Configuration
    ]
  end

  def self.for_cookbook(name, &block)
    if configurations.has_key? name
      ingredient_class = configurations[name]
    else
      ingredient_class = Configuration::Root.create nil, name
      configurations[name] = ingredient_class

      top_level = Module.new do
        define_method name do
          return ingredients[name] if ingredients.has_key? name
          ingredients[name] = ingredient_class.new self
        end
      end

      include_classes.each do |class_|
        class_.__send__ :include, Accessor, top_level
      end
    end

    ingredient_class.add_ingredients &block
  end

  def self.set_defaults(context)
    configurations.each_key do |name|
      puts "SETTING DEFAULTS FOR #{name.inspect} ON #{context.node.object_id}"
      puts "\tATTRIBUTES IN: #{context.node[name].inspect}"
      context.send(name).set_defaults
      puts "\tATTRIBUTES OUT: #{context.node[name].inspect}"
    end
  end
end
