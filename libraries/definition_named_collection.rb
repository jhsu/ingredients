require File.join(File.dirname(__FILE__), 'configuration_named_item')
require File.join(File.dirname(__FILE__), 'definition_collection_base')

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
