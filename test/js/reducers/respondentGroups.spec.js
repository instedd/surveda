/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/respondentGroups'
import * as actions from '../../../web/static/js/actions/respondentGroups'
import { playActionsFromState } from '../spec_helper'

describe('respondents reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, surveyId: null, items: null, invalidRespondents: null, uploading: false})
  })

  it('should start fetching respondent group', () => {
    const surveyId = 200
    const result = reducer(initialState, actions.startFetchingRespondentGroups(surveyId))
    expect(result.fetching).toEqual(true)
    expect(result.surveyId).toEqual(surveyId)
  })

  it('should receive respondent groups', () => {
    const surveyId = 200
    const respondentGroups = {1: {id: 1}}
    const r1 = reducer(initialState, actions.startFetchingRespondentGroups(surveyId))
    const result = reducer(r1, actions.receiveRespondentGroups(surveyId, respondentGroups))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(respondentGroups)
    expect(result.surveyId).toEqual(surveyId)
  })

  it('should receive respondent group', () => {
    const surveyId = 200
    const respondentGroups = {1: {id: 1}}
    const respondentGroup2 = {id: 2, name: 'file.csv'}
    const result = playActions([
      actions.startFetchingRespondentGroups(surveyId),
      actions.receiveRespondentGroups(surveyId, respondentGroups),
      actions.receiveRespondentGroup(respondentGroup2)
    ])
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual({
      1: {id: 1},
      2: respondentGroup2
    })
    expect(result.surveyId).toEqual(surveyId)
  })

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
