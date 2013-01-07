require File.join(File.dirname(__FILE__), 'definition_collection_base')

module Ingredients
  class Definition
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
