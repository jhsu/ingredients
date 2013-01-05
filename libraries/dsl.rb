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
  module Dsl
    def attribute(name, options={})
      add_definition Definition::Attribute, name, options
    end

    def data_bag_attribute(name, options={})
      add_definition Definition::DataBagAttribute, name, options
    end

    def data_bag_item(data_bag_id, data_bag_item_id)
      @data_bag_id = data_bag_id
      @data_bag_item_id = data_bag_item_id
    end

    def named_collection(name, options={}, &block)
      add_definition Definition::NamedCollection, name, options, &block
    end

    def namespace(name, options={}, &block)
      add_definition Definition::Namespace, name, options, &block
    end

    def ordered_collection(name, options={}, &block)
      add_definition Definition::OrderedCollection, name, options, &block
    end

    def search_collection(name, options={}, &block)
      add_definition Definition::SearchCollection, name, options, &block
    end
  end
end
