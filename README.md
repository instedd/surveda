# Ask

## Dockerized development

To get started checkout the project, then execute `./dev-setup.sh`

To run the app: `docker-compose up`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To open a shell in a container: `docker exec -it ask_db_1 bash`, where `ask_db_1` is a container name. You can list containers with `docker ps`.

To start an Elixir console in your running Phoenix app container: `docker exec -it ask_app_1 iex -S mix`.

## Linting and Formatting

To help us keep a consistent coding style, we're using StandardJS. Follow their instructions to install it: http://standardjs.com/#install

If you're using Sublime, you can setup a Build System that will use StandardJS to format your code when you hit `Ctrl+B`. To do so:

1. In Sublime, go to `Tools -> Build System -> New Build System...`
1. A file will open, replace its contents with:

```
{
  "cmd": ["standard", "--fix", "$file"],
  "selector": "source.js"
}
```
1. Save. That's it. When you want to format, just hit `Ctrl+B`. Note that the formatter is a bit slow, so it's not a good idea to format on save.

## Learn more

* Phoenix
  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
