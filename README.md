
Easily add referer access to your API by enabling
this plugin.

----

## Configuration

Configuring the plugin is as simple as a single API call, you can configure and
enable it for your [API][api-object] by executing the following request on your
Kong server:

```bash
$ curl -X POST http://kong:8001/apis/{api}/plugins \
    --data "name=cors" \
    --data "config.origins=http://mockbin.com" \
    --data "config.methods=GET, POST" \
    --data "config.headers=Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Auth-Token" \
    --data "config.exposed_headers=X-Auth-Token" \
    --data "config.credentials=true" \
    --data "config.max_age=3600"
```

`api`: The `id` or `name` of the API that this plugin configuration will target

You can also apply it for every API using the `http://kong:8001/plugins/`
endpoint. Read the [Plugin Reference](https://getkong.org/docs/latest/admin-api/#add-plugin) for
more information.

form parameter                             | default | description
---:                                       | ---     | ---
`name`                                     |         | Name of the plugin to use, in this case: `referer`
`config.referes`                           |         | A comma-separated list of allowed domains for the `referer` header. If you wish to allow all referer, add `*` as a single value to this configuration field.

----


[api-object]: https://getkong.org/docs/latest/admin-api/#api-object
