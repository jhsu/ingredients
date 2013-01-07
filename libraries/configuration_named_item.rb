module Ingredients
  class Configuration

    #
    # Represents an item in a named collection. The following excerpt from a
    # role file would create three `NamedItem`s, with names of `primary`,
    # `secondary`, and `guest`. They would be accessed through
    # `my_service.clusters[:primary]`, etc.
    #
    # ```ruby
    # override_attributes({
    #   my_service: {
    #     clusters: {
    #       primary:   {                                   },
    #       secondary: {owner: 'admin2'                    },
    #       guest:     {owner: 'admin3', guest_access: true}
    #     }
    #   }
    # })
    # ```
    #
    class NamedItem < Configuration

      #
      # The name of this item in the collection.
      #
      # @return [String, Symbol] This item's name.
      #
      attr_reader :name

      #
      # Retrieves this `NamedItem`'s node attributes, or an empty Mash if there
      # are no corresponding node attributes. This should be called only by the
      # various {Definition} `get` methods, and only to retrieve the value of a
      # configuration option (ie, not to set it). Returns an empty Mash if there
      # are no corresponding node attributes.
      #
      # @return [Chef::Node::Attribute, Mash] This item's node attributes.
      #
      def config
        if parent.config.nil? ||
            !parent.config.has_key?(configuration_name) ||
            !parent.config[configuration_name].has_key?(name)
          Mash.new
        else
          parent.config[configuration_name][name]
        end
      end

      #
      # Retrieves the portion of this configuration's data bag item that
      # corresponds to this `NamedItem`, or an empty Mash if it does not exist.
      # This should only be called by the various {Definition} `get` methods.
      #
      # @return [Chef::Node::Attribute, Mash] This item's data bag item.
      #
      def data_bag_item
        return @data_bag_item if instance_variable_defined? :@data_bag_item
        @data_bag_item = parent.data_bag_item.
            fetch(configuration_name, Mash.new).fetch(name, Mash.new)
      end

      #
      # Retrieves this `NamedItem`'s default node attributes. This should be
      # called only by the various {Definition} `set_defaults` methods, and only
      # to set the default value of a configuration option (ie, not to get it).
      #
      # @return [Chef::Node::Attribute] This item's node attributes.
      #
      def default
        parent.default[configuration_name][name]
      end

      #
      # Creates a new `NamedItem`. This should only be called by
      # {Definition::NamedCollection#value}.
      #
      # @param [#node] parent The new object's parent.
      # @param [String, Symbol] name The new object's name.
      #
      def initialize(parent, name)
        super parent
        @name = name
      end

      #
      # Get only the keys that this configuration contributes to the key path.
      # This excludes the parent's key path.
      #
      # @return [Array<Integer, String, Symbol>] The key path for this
      #         `NamedItem`, relative to the parent.
      #
      def path_components
        [configuration_name, name]
      end
    end
  end
end
