module Ingredients
  class Configuration

    #
    # Represents an item in a namespace. The following excerpt from a role file
    # would have one corresponding `Namespace` object with a name of
    # `logrotate`. It would be accessed through `my_service.logrotate`.
    #
    # ```ruby
    # override_attributes({
    #   my_service: {
    #     logrotate: {
    #       frequency: :weekly,
    #       rotate:    4
    #     }
    #   }
    # })
    # ```
    #
    class Namespace < Configuration

      #
      # Retrieves this `Namespace`'s node attributes, or `nil` if there are no
      # corresponding node attributes. This should be called only by the various
      # {Definition} `get` methods, and only to retrieve the value of a
      # configuration option (ie, not to set it).
      #
      # @return [Chef::Node::Attribute, nil] This item's node attributes.
      #
      def config
        unless parent.config.nil?
          parent.config[configuration_name]
        end
      end

      #
      # Retrieves the portion of this configuration's data bag item that
      # corresponds to this `Namespace`, or an empty Mash if it does not exist.
      # This should only be called by the various {Definition} `get` methods.
      #
      # @return [Chef::Node::Attribute, Mash] This item's data bag item.
      #
      def data_bag_item
        return @data_bag_item if instance_variable_defined? :@data_bag_item
        @data_bag_item = parent.data_bag_item.fetch configuration_name, Mash.new
      end

      #
      # Retrieves this `Namespace`'s default node attributes. This should be
      # called only by the various {Definition} `set_defaults` methods, and only
      # to set the default value of a configuration option (ie, not to get it).
      #
      # @return [Chef::Node::Attribute] This item's node attributes.
      #
      def default
        parent.default[configuration_name]
      end
    end
  end
end
