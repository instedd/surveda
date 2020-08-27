/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/respondents'
import * as actions from '../../../web/static/js/actions/respondents'

describe('respondents reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, surveyId: null, items: null, order: [], sortBy: null, sortAsc: true, page: {number: 1, size: 5, totalCount: 0}, filter: null, fields: null, selectedFields: null})
  })

  it('should start fetching respondents', () => {
    const [surveyId, pageSize, pageNumber, filter] = [1, 2, 3, '4']

    const result = reducer(
      initialState,
      actions.startFetchingRespondents(surveyId, pageSize, pageNumber, filter)
    )

    expect(result.fetching).toEqual(true)
    expect(result.surveyId).toEqual(surveyId)
    expect(result.page.size).toEqual(pageSize)
    expect(result.page.number).toEqual(pageNumber)
    expect(result.filter).toEqual(filter)
  })

  it('should receive respondents', () => {
    const surveyId = 200
    const respondents = {1: {id: 1}}
    const respondentsCount = 123
    const r1 = reducer(initialState, actions.startFetchingRespondents(surveyId, 1))
    const result = reducer(r1, actions.receiveRespondents(respondents, respondentsCount))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(respondents)
    expect(result.surveyId).toEqual(surveyId)
    expect(result.page.totalCount).toEqual(123)
  })
})
