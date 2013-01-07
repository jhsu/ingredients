module Ingredients
  class Configuration

    #
    # Represents an item in an ordered collection. The following excerpt from a
    # role file would have two corresponding `OrderedCollection` objects. They
    # would be accessed through `my_service.listen_addresses[0]`, etc.
    #
    # ```ruby
    # override_attributes({
    #   my_service: {
    #     listen_addresses: [
    #       {address: '127.0.0.1', auth: :ident},
    #       {address: '0.0.0.0'                }
    #     ]
    #   }
    # })
    # ```
    #
    class OrderedItem < Configuration

      #
      # Defines an attribute inside an ordered item. This overrides the standard
      # definition in {Dsl#attribute} to provide a slightly different
      # implementation with the same interface.
      #
      # @see Definition::OrderedItemAttribute
      #
      # @param name [String, Symbol] The name of the attribute.
      # @param options [Hash{Symbol => Object}] Attribute options.
      #
      def self.attribute(name, options={})
        add_definition Definition::OrderedItemAttribute, name, options
      end

      #
      # Returns the index of this `OrderedItem` in the collection.
      #
      # @return [Integer] This item's index.
      #
      attr_reader :index

      #
      # Retrieves this `OrderedItem`'s node attributes. This should be called
      # only by the various {Definition} `get` and `set_default` methods, and
      # can be used to both get values and set defaults. (For consistency with
      # other classes, `config` should be used to retrive values, and `default`
      # should be used to set defaults.)
      #
      # @return [Chef::Node::Attribute] This item's node attributes.
      #
      def config
        return @config if instance_variable_defined? :@config
        @config = parent.config[configuration_name][index]
      end

      alias_method :default, :config

      #
      # Creates a new `OrderedItem`. This should only be called by
      # {Definition::OrderedCollection#value}.
      #
      # @param [#node] parent This `OrderedItem`'s parent object.
      # @param [Integer] index The index of this `OrderedItem` within its
      #        collection.
      #
      def initialize(parent, index)
        super parent
        @index = index
      end

      #
      # Get only the keys that this configuration contributes to the key path.
      # This excludes the parent's key path.
      #
      # @return [Array<Integer, String, Symbol>] The key path for this
      #         `OrderedItem`, relative to its parent.
      #
      def path_components
        [configuration_name, index]
      end
    end
  end
end
