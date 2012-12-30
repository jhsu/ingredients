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
    class SearchCollection < CollectionBase
      self.collection_class = Configuration::SearchItem

      def as
        return @as if instance_variable_defined? :@as
        @as = options.fetch :as, name
      end

      def set_defaults(configuration)
        get(configuration).each_value &:set_defaults
      end

      def sources
        return @sources if instance_variable_defined? :@sources
        @sources = options.fetch :sources, [name]
      end

      def value(configuration)
        Mash.new.tap do |value|
          path = configuration.path + [as]
          sources.each do |source|
            Chef::Search::Query.new.search source, '*:*' do |item|
              raw_data = item.raw_data
              path.each do |component|
                raw_data = raw_data.nil? ? nil : raw_data[component]
              end
              unless raw_data.nil?
                value[item.id] = item_class.new configuration, item.id, raw_data
              end
            end
          end
        end
      end
    end
  end
end
