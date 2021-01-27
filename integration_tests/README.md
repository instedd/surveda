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

4. Setup a ncd local gateway simulator

  ```
  $ docker run --rm -it \
    -e HOST=nuntium-stg.instedd.org \
    -e ACCOUNT=***** \
    -e CHANNEL_NAME=***** \
    -e CHANNEL_PASSWORD=******** \
    -e DELAY_REPLY_MIN_SECONDS=20 -e DELAY_REPLY_MAX_SECONDS=25 -e DELAY_REPLY_PERCENT=1 \
    instedd/lgwsim
  ```

  Follow the setup instructions in [instedd/ncd_local_gateway_simulator](https://github.com/instedd/ncd_local_gateway_simulator) to get the required information.
