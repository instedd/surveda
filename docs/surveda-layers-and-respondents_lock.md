# Surveda Layers and Respondent Locks

Read [this PR](https://github.com/instedd/surveda/pull/1667) for further information

## Surveda layers

![image](https://user-images.githubusercontent.com/13237343/76789776-43e71c00-679c-11ea-8cf5-7188a1e20b2a.png)

* `runtime/broker.ex` -> Is the one that uses `GenServer`. Actions that must be triggered by time passing. Iterates once a minute and is the responsible for polling running surveys, retrying respondents and so. Surveda is being “proactive"
* `runtime/survey.ex` -> Is just a simple elixir module that has the logic of knowing how to handle the next step of the survey and updating the respondent (among a few other tiny things)

## Respondent locks

All the components at the _TriggeringLayer_ are responsible of locking the action per-respondent and all the functions in _CoreLayer_ know nothing of locks.

The main reason for taking this desition was that [Mutex](https://hexdocs.pm/mutex/readme.html) it's not a reentrant Mutex. So, deadlocks can occur if a respondent is locked more than once in the same process.

Below the places where the respondent locks are done

### Broker

Every time the broker is being proactive

* `mark_stalled_for_eight_hours_respondents_as_failed`
* `retry_respondents`
* `poll_active_surveys`

See [this commit](https://github.com/instedd/surveda/pull/1667/commits/39f67f1584a137bd9b1ac4efa9def11e4d690015) for further details

### Verboice channel

Every time Surveda receives a callback from Verboice

* `callback`: both status and respondent digits

See [this commit](https://github.com/instedd/surveda/pull/1667/commits/ebd136cdeec1c79eeecd61809f5f3d971c2bd895) for further details

### Nuntium channel

* `callback`: both status and respondent responses

Every time Surveda receives a callback from Nuntium

See [this commit](https://github.com/instedd/surveda/pull/1667/commits/4834803363dc7173f02d16f7b20ea0a6f4204ec3) for further details

### Mobile survey controller

Every time a respondent interacts with Surveda

* `sync_step`

See [this commit](https://github.com/instedd/surveda/pull/1667/commits/d2f3aa59f3fe21b869009c72bb369a4775b7b133) for further details
