// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/activities'
import * as actions from '../../../web/static/js/actions/activities'

describe('activities reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, projectId: null, items: null, order: [], sortBy: 'insertedAt', sortAsc: false, page: {number: 1, size: 15, totalCount: 0}})
  })

  it('should start fetching activities', () => {
    const projectId = 100
    const result = reducer(initialState, actions.startFetchingActivities(projectId, 3))
    expect(result.fetching).toEqual(true)
    expect(result.page.number).toEqual(3)
    expect(result.projectId).toEqual(projectId)
  })

  it('should receive activities', () => {
    const projectId = 100
    const activities = {'1': {'action': 'edit', 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingActivities(projectId, 1))
    const result = reducer(r1, actions.receiveActivities(projectId, 1, activities, 20, [1]))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(activities)
    expect(result.page.totalCount).toEqual(20)
    expect(result.order).toEqual([1])
  })

  it('should update order', () => {
    const r1 = reducer(initialState, actions.updateOrder(true))
    expect(r1.sortAsc).toEqual(true)
    const r2 = reducer(r1, actions.updateOrder(false))
    expect(r2.sortAsc).toEqual(false)
  })
})
