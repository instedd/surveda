// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/activities'
import * as actions from '../../../web/static/js/actions/activities'

describe('activities reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, filter: null, items: null, order: null, sortBy: 'insertedAt', sortAsc: false, page: {index: 0, size: 15}})
  })

  it('should start fetching activities', () => {
    const projectId = 100
    const result = reducer(initialState, actions.startFetchingActivities(projectId))
    expect(result.fetching).toEqual(true)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
  })

  it('should receive activities', () => {
    const projectId = 100
    const activities = {'1': {'action': 'edit', 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingActivities(projectId))
    const result = reducer(r1, actions.receiveActivities(projectId, activities))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(activities)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
    expect(result.order).toEqual([1])
  })

  it('should sort surveys by insertedAt', () => {
    const projectId = 100
    const activities = {'1': {'id': 1, 'insertedAt': '2018-03-01T00:00:00'}, '2': {'id': 2, 'insertedAt': '2018-03-02T00:00:00'}}
    const r1 = reducer(initialState, actions.startFetchingActivities(projectId))
    const r2 = reducer(r1, actions.receiveActivities(projectId, activities))
    const r3 = reducer(r2, actions.sortActivitiesBy('insertedAt'))
    expect(r3.order).toEqual([1, 2])
    const r4 = reducer(r3, actions.sortActivitiesBy('insertedAt'))
    expect(r4.order).toEqual([2, 1])
  })

  it('should go to next and previous page', () => {
    const r1 = reducer(initialState, actions.nextActivitiesPage())
    expect(r1.page).toEqual({index: 15, size: 15})
    const r2 = reducer(r1, actions.nextActivitiesPage())
    expect(r2.page).toEqual({index: 30, size: 15})
    const r3 = reducer(r2, actions.previousActivitiesPage())
    expect(r3.page).toEqual({index: 15, size: 15})
  })
})
