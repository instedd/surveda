// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/surveys'
import * as actions from '../../../web/static/js/actions/surveys'
import { survey } from '../fixtures'

describe('surveys reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, filter: null, items: null, order: null, sortBy: null, sortAsc: true, page: {index: 0, size: 6}})
  })

  it('should start fetching surveys', () => {
    const projectId = 100
    const result = reducer(initialState, actions.startFetchingSurveys(projectId))
    expect(result.fetching).toEqual(true)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
  })

  it('should receive surveys', () => {
    const projectId = 100
    const surveys = {'1': {...survey, 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingSurveys(projectId))
    const result = reducer(r1, actions.receiveSurveys(projectId, surveys))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(surveys)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
    expect(result.order).toEqual([1])
  })

  it('should start fetching surveys for a different project', () => {
    const projectId = 100
    const surveys = {'1': {...survey, id: 1}}
    const r1 = reducer(initialState, actions.startFetchingSurveys(projectId))
    const r2 = reducer(r1, actions.receiveSurveys(projectId, surveys))
    const r3 = reducer(r2, actions.startFetchingSurveys(projectId + 1))
    expect(r3.items).toEqual(null)
  })

  it('should sort surveys by name', () => {
    const projectId = 100
    const surveys = {'1': {...survey, id: 1, name: 'foo'}, '2': {...survey, id: 2, name: 'bar'}}
    const r1 = reducer(initialState, actions.startFetchingSurveys(projectId))
    const r2 = reducer(r1, actions.receiveSurveys(projectId, surveys))
    const r3 = reducer(r2, actions.sortSurveysBy('name'))
    expect(r3.order).toEqual([2, 1])
    const r4 = reducer(r3, actions.sortSurveysBy('name'))
    expect(r4.order).toEqual([1, 2])
  })

  it('should go to next and previous page', () => {
    const r1 = reducer(initialState, actions.nextSurveysPage())
    expect(r1.page).toEqual({index: 6, size: 6})
    const r2 = reducer(r1, actions.nextSurveysPage())
    expect(r2.page).toEqual({index: 12, size: 6})
    const r3 = reducer(r2, actions.previousSurveysPage())
    expect(r3.page).toEqual({index: 6, size: 6})
  })

  it('should delete survey', () => {
    const projectId = 100
    const surveys = {'1': {...survey, 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingSurveys(projectId))
    const r2 = reducer(r1, actions.receiveSurveys(projectId, surveys))
    const r3 = reducer(r2, actions.deleted(surveys['1']))
    expect(r3.items).toEqual({})
    expect(r3.order).toEqual([])
  })
})
