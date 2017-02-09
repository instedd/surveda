/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/userSettings'
import * as actions from '../../../web/static/js/actions/userSettings'

describe('user settings reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, settings: null})
  })

  it('should start fetching settings', () => {
    const userId = 2
    const result = reducer(initialState, actions.startFetchingSettings(userId))
    expect(result.fetching).toEqual(true)
    expect(result.settings).toEqual(null)
  })

  it('should receive settings', () => {
    const userId = 2
    const params = {
      'settings': {'onboarding': {'questionnaire': true}}
    }
    const r1 = reducer(initialState, actions.startFetchingSettings(userId))
    const result = reducer(r1, actions.receiveSettings(params, userId))
    expect(result.fetching).toEqual(false)
    expect(result.settings).toEqual(params.settings)
  })
})
