module Ingredients
  module Dsl
    def attribute(name, options={})
      add_definition Definition::Attribute, name, options
    end

    def data_bag_attribute(name, options={})
      add_definition Definition::DataBagAttribute, name, options
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
