/* eslint-env mocha */
import expect from 'expect'
import assert from 'assert'
import { playActionsFromState } from '../spec_helper'
import reducer from '../../../web/static/js/reducers/survey'
import * as actions from '../../../web/static/js/actions/survey'
import * as questionnaireActions from '../../../web/static/js/actions/questionnaire'

describe('survey reducer', () => {
  const initialState = reducer(undefined, {})

  const playActions = playActionsFromState(initialState, reducer)

  it('has a sane initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.filter).toEqual(null)
    expect(initialState.data).toEqual(null)
    expect(initialState.dirty).toEqual(false)
    expect(initialState.saving).toEqual(false)
  })

  it('should fetch', () => {
    assert(!actions.shouldFetch({fetching: true, filter: {projectId: 1, id: 1}}, 1, 1))
    assert(actions.shouldFetch({fetching: true, filter: null}, 1, 1))
    assert(actions.shouldFetch({fetching: true, filter: {projectId: 1, id: 1}}, 2, 2))
    assert(actions.shouldFetch({fetching: false, filter: null}, 1, 1))
    assert(actions.shouldFetch({fetching: false, filter: {projectId: 1, id: 1}}, 1, 1))
  })

  it('fetches a survey', () => {
    const state = playActions([
      actions.fetch(1, 1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        projectId: 1,
        id: 1
      },
      data: null
    })
  })

  it('receives a survey', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey)
    ])
    expect(state.fetching).toEqual(false)
    expect(state.data).toEqual(survey)
  })

  it('receiving a survey without an initial fetch should discard the survey', () => {
    const state = playActions([
      actions.receive(survey)
    ])
    expect(state.fetching).toEqual(false)
    expect(state.filter).toEqual(null)
    expect(state.data).toEqual(null)
  })

  it('clears data when fetching a different survey', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.fetch(2, 2)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        projectId: 2,
        id: 2
      },
      data: null
    })
  })

  it('keeps old data when fetching new data for the same filter', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.fetch(1, 1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      data: survey
    })
  })

  it('ignores data received based on different filter', () => {
    const state = playActions([
      actions.fetch(2, 2),
      actions.receive(survey)
    ])

    expect(state).toEqual({
      ...state,
      filter: {projectId: 2, id: 2},
      fetching: true,
      data: null
    })
  })

  it('should be marked as dirty if something changed', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed')
    ])

    expect(state).toEqual({
      ...state,
      dirty: true
    })
  })

  it('should be marked saving when saving', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed'),
      actions.saving()
    ])

    expect(state).toEqual({
      ...state,
      dirty: false,
      saving: true
    })
  })

  it('should be marked clean and saved when saved', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed'),
      actions.saving(),
      actions.saved(survey)
    ])

    expect(state).toEqual({
      ...state,
      saving: false,
      dirty: false
    })
    expect(state.data.scheduleDayOfWeek)
    .toEqual({'sun': true, 'mon': true, 'tue': true, 'wed': false, 'thu': true, 'fri': true, 'sat': true})
  })

  it('should update state when saved', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed'),
      actions.saving(),
      actions.saved({...survey, state: 'foo'})
    ])

    expect(state.data.state).toEqual('foo')
  })

  it('should be marked dirty if there were a change in the middle', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed'),
      actions.saving(),
      actions.toggleDay('wed'),
      actions.saved(survey)
    ])

    expect(state).toEqual({
      ...state,
      saving: false,
      dirty: true
    })
    expect(state.data).toEqual(survey)
  })

  it('shouldn\'t be marked as dirty if something changed in a different reducer', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      questionnaireActions.changeName('foo')
    ])
    expect(state).toEqual({
      ...state,
      dirty: false
    })
  })

  it('should toggle a single day preserving the others', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.toggleDay('wed')
    ])
    expect(state.data.scheduleDayOfWeek)
    .toEqual({'sun': true, 'mon': true, 'tue': true, 'wed': false, 'thu': true, 'fri': true, 'sat': true})
  })

  it('should set timezone', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.setTimezone('America/Cayenne')
    ])
    expect(result.data.timezone).toEqual('America/Cayenne')
  })

  it('should change sms retry configuration property', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.changeSmsRetryConfiguration('15h 1d')
    ])
    expect(state.data.smsRetryConfiguration).toEqual('15h 1d')
  })

  it('should change ivr retry configuration property', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(survey),
      actions.changeIvrRetryConfiguration('15h 1d')
    ])
    expect(state.data.ivrRetryConfiguration).toEqual('15h 1d')
  })
})

const survey = {
  'id': 1,
  'projectId': 1,
  'name': 'Foo',
  'cutoff': 123,
  'state': 'ready',
  'questionnaireId': 1,
  'scheduleDayOfWeek': {'sun': true, 'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true, 'sat': true},
  'scheduleStartTime': '02:00:00',
  'scheduleEndTime': '06:00:00',
  'channels': [1],
  'respondentsCount': 2
}
