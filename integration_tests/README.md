# Surveda Integration Tests

This directory contains integration test that requires some manual setup before running.

1. Install dependencies

  ```
  $ yarn install
  ```

2. Copy `cypress.sample.json` to `cypress.json`. Edit the credentials and needed values.

  ```
  $ cp cypress.sample.json cypress.json
  # Edit cypress.json
  ```

3. Run cypress

  ```
  $ npm run cypress:open # or cypress:run
  ```

Alternative it can be run with `$ docker-compose run --rm cypress` directly.
