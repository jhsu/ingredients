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

    ingredient_class.add_ingredients &block
  end

  def self.set_defaults(context)
    configurations.each_key {|name| context.send(name).set_defaults}
  end
end
