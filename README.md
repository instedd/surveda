# Ask

## Dockerized development

To get started checkout the project, then execute `./dev-setup.sh`

To run the app: `docker-compose up`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To open a shell in a container: `docker exec -it ask_db_1 bash`, where `ask_db_1` is a container name. You can list containers with `docker ps`.

To start an Elixir console in your running Phoenix app container: `docker exec -it ask_app_1 iex -S mix`.

## Linting

To help us keep a consistent coding style, we're using ESLint. In the root of the project there's a `.eslintrc` file specifying the project's style rules. 

To lint-check your code, you'll need to install some `npm` packages:

`npm install -g eslint eslint-plugin-import eslint-plugin-react babel-eslint`

Note: we're not installing project-local ESLint packages because we generally work on editors in the host machine instead and the project source code is mounted on a Docker container.

## Learn more

* Phoenix
  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
