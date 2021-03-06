# Chef Ingredients

**A humble suggestion for keeping complex Chef cookbooks maintainable.**

While developing Chef cookbooks for my own project, I found the code in the
community cookbooks hard to follow and difficult to adapt, so I started from
scratch and worked through a few common, nontrivial services. Along the way, I
formed some opinions about what would make complex cookbooks easier to write,
read, maintain, and use. If you agree, `ingredients` might be for you:

* Each service only requires one cookbook to be configured, and one recipe to be
  added to a run list. Interdependencies between cookbooks are kept to a
  minimum.
* Node attributes are used to store almost all configuration parameters.
* Data bags are used to store directory objects like users, which cut across
  services.
* Configuration should never be hard-coded into recipes.
* Attributes use the same overall structure for both node attributes and data
  bags.
* A cookbook's attributes file should be complete and easy to read & understand.

If you want to see how this all fits together, [skip right to the end]
(#full-example).


## Adding ingredients

There are just a few simple steps to add ingredients to your cookbook:

Add the `ingredients` cookbook to your Chef repo. _(NB: There are better ways to
do this.)_

```sh
git submodule add git://github.com/zobar/ingredients.git cookbooks/ingredients
```

Declare your cookbook's dependency on `ingredients` in `metadata.rb`:

```ruby
depends 'ingredients'
```

Include the `ingredients` recipe as the first line in your `recipes/default.rb`:

```ruby
include_recipe 'ingredients'
```

Now you can define your ingredients and use them in your cookbook's recipes and
templates.


## Defining ingredients

`ingredients` provides a DSL for defining the structure of your configuration
parameters and their default values. These go in your cookbook's
`attributes/default.rb` file. All definitions go inside a `for_cookbook` block.

### `attribute`

Simple attributes are defined with an `attribute` statement. Simple attributes
include booleans, numbers, strings, and arrays of booleans, numbers, and
strings. Attributes can optionally have a default value; if a default value is
not provided, it is assumed to be `nil`.

```ruby
Ingredients.for_cookbook :my_service do
  attribute :config_directory, default: '/etc/my_service'
  attribute :data_directory,   default: '/var/lib/my_service'
end
```

The preceding definition is roughly equivalent to the following raw Chef code,
although, as you'll see later, it also defines a number of other useful helpers.

```ruby
default[:my_service][:config_directory] = '/etc/my_service'
default[:my_service][:data_directory]   = '/var/lib/my_service'
```


### `data_bag_attribute`

You may want to place sensitive configuration parameters inside a data bag
rather than your environment and role definitions. For these, you can define a
`data_bag_attribute`. This definition works the same way as `attribute`, except
the value is stored in a data bag item. You don't need special handling for keys
that are missing from the data bag item; `ingredients` will detect these for you
and fall back to the default value. The data bag item these are pulled from is
defined at the beginning of the class with `data_bag_item`, and applies to all
`data_bag_attribute` definitions for that cookbook.

```ruby
Ingredients.for_cookbook :my_service do
  data_bag_item 'my_service', 'secure_config'

  data_bag_attribute :ssl_certificate
  data_bag_attribute :ssl_key
end
```

The preceding definition will look for an item named `secure_config` in a data
bag called `my_service` which looks like this. Note the `my_service` key at the
top level: redundant though this may seem, this enforces consistency between
node attributes and data bag items, and also prevents naming conflicts when
multiple cookbooks use the same data bag item.

```json
{
  "id": "secure_config",
  "my_service": {
    "ssl_certificate": "-----BEGIN CERTIFICATE-----\nMII...",
    "ssl_key":         "-----BEGIN RSA PRIVATE KEY-----\nMII..."
  }
}
```

### `namespace`

You can use a `namespace` to nest related attributes. It is strongly recommended
that you define a namespace for each configuration file. This makes it easier
for the users of your cookbook to cross-reference your attributes file with the
package's documentation. It also makes it easier to write templates.

```ruby
Ingredients.for_cookbook :my_service do
  namespace :logrotate do
    attribute :compress,  default: true
    attribute :frequency, default: :daily
    attribute :rotate,    default: 5
  end
end
```

This is roughly equivalent to the following raw Chef code, though as you can see
it's a bit less repetitive.

```ruby
default[:my_service][:logrotate][:compress]  = true
default[:my_service][:logrotate][:frequency] = :daily
default[:my_service][:logrotate][:rotate]    = 5
```

### `ordered_collection`

Sometimes a service will take a list of similar configuration objects. The most
natural way of representing these is with an array of hashes, but Chef has some
difficulty dealing with that kind of structure. `ingredients` can take care of
this for you, too, and provides fallback behavior consistent with other
constructs.

```ruby
Ingredients.for_cookbook :my_service do
  ordered_collection :listen_addresses do
    attribute :address
    attribute :port,    default: 1234
    attribute :auth,    default: :md5
  end
end
```

This does not have a direct equivalent in raw Chef code, but it allows you to
make the following configuration in your role file. This example defines two
`listen_addresses`, one with an `address` of `127.0.0.1` and an `auth` of
`:ident`; and one with an `address` of `0.0.0.0` and the default `auth` of
`:md5`. Both will use the default `port`, `1234`.

```ruby
override_attributes({
  my_service: {
    listen_addresses: [
      {address: '127.0.0.1', auth: :ident},
      {address: '0.0.0.0'                }
    ]
  }
})
```

### `named_collection`

Sometimes it makes more sense to provide a named collection of configuration
objects, corresponding to a hash of hashes. An example of this might be to
describe databases in an RDBMS. This differs subtly from a `namespace` in that
the keys in the hash are not known ahead of time. For this situation, use a
`named_collection` definition.

```ruby
Ingredients.for_cookbook :my_service do
  named_collection :clusters, default: 'main' do
    attribute :guest_access, default: false
    attribute :owner,        default: 'admin'
  end
end
```

If any values are provided in the node configuration, each of them is merged
with the default attributes in the definition. The following role file creates
three clusters. The first, `primary`, inherits all the default values. It also
demonstrates an `ingredients` idiom: an empty hash means "present, with all
default values." The second, `secondary`, overrides the owner but leaves
`guest_access` at `false`. The third, `guest`, overrides both `owner` and
`guest_access`.

```ruby
override_attributes({
  my_service: {
    clusters: {
      primary:   {                                   },
      secondary: {owner: 'admin2'                    },
      guest:     {owner: 'admin3', guest_access: true}
    }
  }
})
```

If a `default` option is provided to the `named_collection`, as above, and no
values are provided at all, one object is created with the given name and all
attributes set to default values. The following role files will all create one
cluster, named `main`, with default `owner` and `guest_access`:

```ruby
override_attributes({})

override_attributes({my_service: {}})

override_attributes({my_service: {clusters: {}}})
```

Had no `default` option been provided to the `named_collection`, these role
files would not have created any clusters at all.


### `search_collection`

Sometimes you want to perform an action for every data bag item that has a
certain key. For instance, you may want to create a user in your service for
every item in the `people` data bag with a certain key. This can be accomplished
with a `search_collection` definition.

```ruby
Ingredients.for_cookbook :my_service do
  named_collection :clusters do
    search_collection :users, as: :user_options, sources: [:people] do
      attribute :login,    default: true
      attribute :password
      attribute :read,     default: true
      attribute :write,    default: false
    end
  end
end
```

This creates a collection called `users` in each cluster which returns all items
in the `people` data bag with a corresponding key. This person has write access
to the `primary` cluster, read access to the `secondary` cluster, and no access
to the `guest` cluster. As always, attributes that are not explicitly provided
fall back to the defaults specified in the definitions. Note that, as with `data
bag attribute`s, the top-level key corresponds to the cookbook so that multiple
cookbooks can share the same data bag items without risking naming conflicts. In
this case, the `admin` user also has some attributes for `postgresql`.

```json
{
  "id": "admin",
  "my_service": {
    "clusters": {
      "primary": {
        "user_options": {
          "password": "psychic-nemesis",
          "write":    true
        }
      },
      "secondary": {
        "user_options": {
          "password": "miniature-ninja"
        }
      }
    }
  },
  "postgresql": {
    "password": "freezing-dangerzone"
  }
}
```


### Helper methods

`ingredients` is actually a slim DSL built around class definitions. This means
that you can define helper methods right in your ingredients that can be used
elsewhere in your cookbook. The following adds a `full_address` helper method to
`listen_addresses` that combines the address and port into one string.

```ruby
Ingredients.for_cookbook :my_service do
  ordered_collection :listen_addresses do
    attribute :address
    attribute :port,    default: 1234

    def full_address
      "#{address}:#{port}"
    end
  end
end
```

### Open definitions

Much like Ruby modules and classes, `ingredients` definitions can be reopened
and new attributes added to them. You should only do this if one cookbook
provides a plugin for another cookbook and it makes more sense to combine the
attributes for both into one hierarchy rather than defining a separate hierarchy
for the plugin. All definition types must match, and all provided options must
be compatible. Thus, a cookbook for a plugin that adds configurations to
`my_service`'s clusters might look like this:

```ruby
Ingredients.for_cookbook :my_service do
  named_collection :clusters do
    namespace :my_plugin do
      attribute :enable, true
    end
  end
end
```

### <a name='full-example'></a>Putting it all together

This is what all the examples look like when combined.

`cookbooks/my_service/attributes/default.rb`:

```ruby
Ingredients.for_cookbook :my_service do
  data_bag_item 'my_service', 'secure_config'

  attribute :config_directory, default: '/etc/my_service'
  attribute :data_directory,   default: '/var/lib/my_service'

  data_bag_attribute :ssl_certificate
  data_bag_attribute :ssl_key

  named_collection :clusters, default: 'main' do
    attribute :guest_access, default: false
    attribute :owner,        default: 'admin'

    search_collection :users, as: :user_options, sources: [:people] do
      attribute :login,    default: true
      attribute :password
      attribute :read,     default: true
      attribute :write,    default: false
    end
  end

  ordered_collection :listen_addresses do
    attribute :address
    attribute :port,    default: 1234
    attribute :auth,    default: :md5

    def full_address
      "#{address}:#{port}"
    end
  end

  namespace :logrotate do
    attribute :compress,  default: true
    attribute :frequency, default: :daily
    attribute :rotate,    default: 5
  end
end
```

`roles/my_service.rb`:

```ruby
run_list 'recipe[my_service]'

override_attributes({
  my_service: {
    clusters: {
      primary:   {                                   },
      secondary: {owner: 'admin2'                    },
      guest:     {owner: 'admin3', guest_access: true}
    },
    listen_addresses: [
      {address: '127.0.0.1', auth: :ident},
      {address: '0.0.0.0'                }
    ],
    logrotate: {
      frequency: :weekly,
      rotate:    4
    }
  }
})
```

`data_bags/people/admin.json`:

```json
{
  "id": "admin",
  "my_service": {
    "clusters": {
      "primary": {
        "user_options": {
          "password": "psychic-nemesis",
          "write":    true
        }
      },
      "secondary": {
        "user_options": {
          "password": "miniature-ninja"
        }
      }
    }
  },
  "postgresql": {
    "password": "freezing-dangerzone"
  }
}
```

`data_bags/my_service/secure_config.json`:

```json
{
  "id": "secure_config",
  "my_service": {
    "ssl_certificate": "-----BEGIN CERTIFICATE-----\nMII...",
    "ssl_key":         "-----BEGIN RSA PRIVATE KEY-----\nMII..."
  }
}
```

## Using ingredients

`Ingredients.for_cookbook` creates a method that is accessible from all areas of
Chef that can be used to access your cookbook's configuration. All attributes
can be accessed from that object using dot syntax. Bracket syntax is not
supported, and accessing an unknown attribute raises `NoMethodError`. Here are
some example expressions and their approximate raw Chef equivalents.

```ruby
my_service.config_directory                # node[:my_service][:config_directory]
my_service.logrotate.frequency             # node[:my_service][:logrotate][:frequency]
my_service.ssl_certificate                 # data_bag_item('my_service', 'secure_config').raw_data['my_service']['ssl_certificate']

my_service.bogus_attribute                 # node[:my_service][:bogus_attribute]
# => NoMethodError                         #   => nil

my_service.listen_addresses.each do |listen_address|
  listen_address.port                      # node[:my_service][:listen_addresses][index].fetch(:port, 1234)
  listen_address.full_address              # "#{node[:my_service][:listen_addresses][index][:address]}:#{node[:my_service][:listen_addresses][index].fetch(:port, 1234)}"
end

my_service.clusters.each do |cluster_name, cluster|
  cluster.owner                            # node[:my_service][:cluster][name][:owner]

  cluster.users.each do |user_name, user|  # search('people', "my_service_clusters_#{cluster_name}_password:*") do |user|
    user.password                          # user['my_service']['clusters'][cluster_name]['password']
  end
end
```

### Ingredients & templates

The top-level ingredient methods are available in templates just as they are
everywhere else, so the following ERB snippet does exactly what you expect:

```erb
<%= my_service.data_directory %>
```

Of course, deeper attributes are available by chaining through the top-level
method, but this can become tedious. If you set up a namespace that corresponds
to each template file, recipes and templates can work together more smoothly.

`cookbooks/my_service/recipes/default.rb`:

```ruby
template '/etc/logrotate.d/my_service' do
  source    'logrotate.erb'
  variables logrotate: my_service.logrotate

  notifies :restart, 'service[my_service]'
end
```

`cookbooks/my_service/templates/logrotate.erb`:

```erb
/var/log/my_service/my_service.log {
  <%= @logrotate.frequency %>
  <%= @logrotate.compress ? 'compress' : 'nocompress' %>
  rotate <%= @logrotate.rotate %>
}
```

## License

Copyright 2012-2013, David P. Kleinschmidt

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
