// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../assets/js/reducers/activities'
import * as actions from '../../../assets/js/actions/activities'

describe('activities reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, projectId: null, items: null, order: [], sortBy: 'insertedAt', sortAsc: false, page: {number: 1, size: 15, totalCount: 0}})
  })

  it('should start fetching activities on project change', () => {
    const [projectId, pageSize, pageNumber, sortAsc] = [1, 2, 3, true]
    const result = reducer(initialState, actions.startFetchingActivities(projectId, pageSize, pageNumber, sortAsc))
    expect(result.fetching).toEqual(true)
    expect(result.projectId).toEqual(projectId)
    expect(result.page.size).toEqual(pageSize)
    expect(result.page.number).toEqual(pageNumber)
    // It ignores sortAsc when the project changes
    expect(result.sortAsc).toEqual(false)
  })

  it('should receive activities', () => {
    const [projectId, pageSize, pageNumber, sortAsc] = [1, 2, 3, true]
    const activities = {'1': {'action': 'edit', 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingActivities(projectId, pageSize, pageNumber, sortAsc))
    const result = reducer(r1, actions.receiveActivities(projectId, activities, 20, [1]))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(activities)
    expect(result.page.totalCount).toEqual(20)
    expect(result.order).toEqual([1])
  })
})
