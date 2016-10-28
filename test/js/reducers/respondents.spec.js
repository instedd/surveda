/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/respondents'
import * as actions from '../../../web/static/js/actions/respondents'

describe('respondents reducer', () => {
  const initialState = reducer(undefined, {})

  it('should store invalid entries', () => {
    const data = {filename: 'invalid.csv', invalidEntries: [{line_number: 1, phone_number: 'aa123'}, {line_number: 2, phone_number: 'ba123'}]}
    const result = reducer(initialState, actions.receiveInvalids(data))
    expect(result.invalidRespondents.filename).toEqual('invalid.csv')
    expect(result.invalidRespondents.invalidEntries[0].line_number).toEqual(1)
    expect(result.invalidRespondents.invalidEntries[1].line_number).toEqual(2)
  })

  it('should clear invalid respondents', () => {
    const data = {filename: 'invalid.csv', invalidEntries: [{line_number: 1, phone_number: 'aa123'}, {line_number: 2, phone_number: 'ba123'}]}
    const preState = reducer(initialState, actions.receiveInvalids(data))
    const result = reducer(preState, actions.clearInvalids())
    expect(!result.invalidRespondents)
  })
})
