/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/questionnaire'

describe('questionnaire reducer', () => {
  const initialState = reducer(undefined, {})

  it('has a sane initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.filter).toEqual({})
    expect(initialState.data).toEqual({})
  })
})
