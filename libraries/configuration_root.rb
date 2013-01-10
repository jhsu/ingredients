require File.join(File.dirname(__FILE__), 'configuration')

module Ingredients
  class Configuration

    #
    # Represents a top-level {Configuration} object. The following excerpt from
    # a role file would have one corresponding `Root` object with a name of
    # `my_service`. It is returned by calling, simply, `my_service`.
    #
    # ```ruby
    # override_attributes({
    #   my_service: {
    #     config_directory: '/etc/my_service',
    #     data_directory:   '/var/lib/my_service'
    #   }
    # })
    # ```
    #
    class Root < Configuration

      class << self
        #
        # The data bag ID set by `data_bag_item`, or `nil` if no data bag item
        # was set.
        #
        # @return [String, Symbol, nil] This service's data bag ID.
        #
        attr_reader :data_bag_id

        #
        # The data bag item ID set by `data_bag_item`, or `nil` if no data bag
        # item was set.
        #
        # @return [String, Symbol, nil] This service's data bag item ID.
        #
        attr_reader :data_bag_item_id
      end

      #
      # Sets which data bag item should be consulted for `data_bag_attribute`s.
      # It is recommended that sensitive configuration parameters like passwords
      # and SSL keys are stored in data bags rather than node attributes.
      #
      # @param [String, Symbol] data_bag_id ID of the item's data bag.
      # @param [String, Symbol] data_bag_item_id ID of the data bag item.
      # @return [void]
      #
      def self.data_bag_item(data_bag_id, data_bag_item_id)
        @data_bag_id = data_bag_id
        @data_bag_item_id = data_bag_item_id
      end

      def_delegators 'self.class', :data_bag_id, :data_bag_item_id

      #
      # Retrieves this `Namespace`'s node attributes, or `nil` if there are no
      # corresponding node attributes. This should be called only by the various
      # {Definition} `get` methods, and only to retrieve the value of a
      # configuration option (ie, not to set it).
      #
      # @return [Chef::Node::Attribute, nil] This item's node attributes.
      #
      def config
        node[configuration_name]
      end

      #
      # Retrieves the portion of this configuration's data bag item that
      # corresponds to this service, or an empty Mash if it does not exist. This
      # should only be called by the various {Definition} `get` methods.
      #
      # @return [Mash] This item's data bag item.
      #
      def data_bag_item
        return @data_bag_item if instance_variable_defined? :@data_bag_item
        raw_data = Mash.new begin
          Chef::DataBagItem.load(data_bag_id, data_bag_item_id).raw_data
        rescue Net::HTTPServerException => err
          {}
        end
        @data_bag_item = raw_data[configuration_name]
      end

      #
      # Retrieves this service's default node attributes. This should be called
      # only by the various {Definition} `set_defaults` methods, and only to set
      # the default value of a configuration option (ie, not to get it).
      #
      # @return [Mash] This item's node attributes.
      #
      def default
        node.default[configuration_name]
      end

      #
      # Get the full path of keys to follow to get to this configuration.
      #
      # @return [Array<Integer, String, Symbol>] The key path for this service.
      #
      def path
        return @path if instance_variable_defined? :@path
        @path = path_components
      end
    end
  end
end
