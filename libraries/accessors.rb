module Ingredients

  #
  # Provides accessors to the configuration instances defined by {for_cookbook}.
  # If you call, for instance,
  #
  # ```ruby
  # Ingredients.for_cookbook :my_service do
  #   # ...
  # end
  # ```
  #
  # This will add an accessor named `my_service` to {Accessors} and, by
  # extension, every class that includes it. This module is already included
  # into several Chef classes: `Chef::Provider`, `Chef::Recipe`,
  # `Chef::Resource`, `Chef::RunContext`, and `Erubis::Context`. It can also be
  # included explicitly in any class that defines a `node` method (though it
  # should be considered a bug if it is not automatically included in a
  # relatively-standard Chef class).
  #
  module Accessors

    #
    # Get the Mash that is used to hold memoized instances of configuration
    # options. As the contents of this Mash may be incomplete, you should
    # instead be accessing configurations through the cookbook-specific accessor
    # method.
    #
    # @return [Mash{String, Symbol => Configuration::Root}] All the
    #         configuration objects accessed so far in this context.
    #
    def ingredients
      return @ingredients if instance_variable_defined? :@ingredients
      @ingredients = Mash.new
    end
  end

  [
    Chef::Provider,
    Chef::Recipe,
    Chef::Resource,
    Chef::RunContext,
    Erubis::Context
  ].each {|class_| class_.__send__ :include, Accessors}
end
