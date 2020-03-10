# Referer verification plugin

Easily add referer access to your API by enabling this plugin.

_NOTE:_ This is not a secure plugin! it is based on the `referer` header that
anyone could spoof. For security consider real authentication plugins.

----

## Installation

Install the rock when building your Kong image/instance:
```
luarocks install kong-plugin-referer
```

Add the plugin to your `custom_plugins` section in `kong.conf`, the `KONG_CUSTOM_PLUGINS` is also available.

```
custom_plugins = referer
```

----

## Compatibility

| Plugin  | Kong version |
|--|--|
| v1.1-1 | < 1.x.x |
| v2.0 | >= 2.0.x |

## Configuration

Configuring the plugin is as simple as a single API call, you can configure and
enable it for your [API][api-object] by executing the following request on your
Kong server:

```bash
$ curl -X POST http://kong:8001/apis/{api}/plugins \
    --data "name=referer" \
    --data "config.referers=mockbin.com, *.mockbin.com" \
```

`api`: The `id` or `name` of the API that this plugin configuration will target

You can also apply it for every API using the `http://kong:8001/plugins/`
endpoint. Read the [Plugin Reference](https://getkong.org/docs/latest/admin-api/#add-plugin) for
more information.

form parameter                             | default | description
---:                                       | ---     | ---
`name`                                     |         | Name of the plugin to use, in this case: `referer`
`config.referers`                           |         | A comma-separated list of allowed domains for the `referer` header. If you wish to allow all referer, add `*` as a single value to this configuration field.

----

## Testing

The code can be tested using the `kong-vagrant` environment.

```shell
# clone the repositories
git clone http://github.com/kong/kong-vagrant.git
cd kong-vagrant
git clone http://github.com/kong/kong.git
git clone http://github.com/eyolas/kong-plugin-referer.git

# checkout the required Kong version
export TEST_VERSION=2.0.2
pushd kong; git checkout $(TEST_VERSION); popd

# Build vagrant with same Kong version and the plugin
KONG_VERSION=$(TEST_VERSION) KONG_PLUGIN_PATH=./kong-plugin-referer vagrant up
vagrant ssh

# Build dev environment
cd /kong
make dev

# Execute tests
bin/busted -v -o gtest /kong-plugin/spec
```


[api-object]: https://getkong.org/docs/latest/admin-api/#api-object
