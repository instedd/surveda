import expect from 'expect'
import surveys from '../../../web/static/js/reducers/surveys'

describe('surveys reducer', () => {
  it('should handle initial state', () => {
    expect(surveys(undefined, {})).toEqual({})
  })
})
