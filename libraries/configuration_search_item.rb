module Ingredients
  class Configuration

    #
    # Represents an item in a search collection. The following excerpt from a
    # data bag item would have one corresponding `SearchItem` named `admin`. It
    # could be accessed through `my_service.user_options[:admin]`.
    #
    # ```json
    # {
    #   "id": "admin",
    #   "my_service": {
    #     "user_options": {
    #       "password": "psychic-nemesis"
    #     }
    #   }
    # }
    # ```
    #
    class SearchItem < Configuration

      #
      # Retrieves this `SearchItem`'s attributes. This should be called only by
      # the various {Definition} `get` and `set_default` methods, and can be
      # used to both get values and set defaults. (For consistency with other
      # classes, `config` should be used to retrive values, and `default` should
      # be used to set defaults.)
      #
      # @return [Mash] This item's attributes.
      #
      attr_reader :config
      alias_method :default, :config

      #
      # This item's data bag item ID.
      #
      # @return [String] This item's data bag item ID.
      #
      attr_reader :name

      #
      # Defines an attribute inside a `SearchItem`. This overrides the standard
      # definition in {Dsl#attribute} to provide a slightly different
      # implementation with the same interface.
      #
      # @see Definition::OrderedItemAttribute
      #
      # @param name [String, Symbol] The name of the attribute.
      # @param options [Hash{Symbol => Object}] Attribute options.
      #
      def self.attribute(name, options={})
        add_definition Definition::SearchItemAttribute, name, options
      end

      #
      # Creates a new `SearchItem`. This should only be called by
      # {Definition::SearchCollection#value}.
      #
      # @param [#node] parent The new object's parent.
      # @param [String, Symbol] name The new object's name.
      # @param [Mash] config The new object's configuration hash.
      #
      def initialize(parent, name, config)
        super parent
        @config = config
        @name = name
      end

      #
      # Get only the keys that this configuration contributes to the key path.
      # This excludes the parent's key path.
      #
      # @return [Array<Integer, String, Symbol>] The key path for this
      #         `SearchItem`, relative to its parent.
      #
      def path_components
        [configuration_name, name]
      end
    end
  end
end
