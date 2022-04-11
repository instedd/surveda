/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../assets/js/reducers/respondents'
import * as actions from '../../../assets/js/actions/respondents'

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
    const respondentId = 1
    const respondents = {respondentId: {id: respondentId}}
    const respondentsCount = 123
    const order = [respondentId]
    const fields = [{type: 'foo', key: 'bar'}]
    const r1 = reducer(initialState, actions.startFetchingRespondents(surveyId, 1))
    const result = reducer(r1, actions.receiveRespondents(respondents, respondentsCount, order, fields))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(respondents)
    expect(result.surveyId).toEqual(surveyId)
    expect(result.page.totalCount).toEqual(respondentsCount)
    expect(result.order).toEqual(order)
    expect(result.selectedFields).toEqual([`${fields[0].type}_${fields[0].key}`])
  })
})
