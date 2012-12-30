require File.join(File.dirname(__FILE__), 'configuration_namespace')
require File.join(File.dirname(__FILE__),
                  'ingredient_definition_collection_base')

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
  class IngredientDefinition
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
