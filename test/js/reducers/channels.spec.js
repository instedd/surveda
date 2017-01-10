// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/channels'
import * as actions from '../../../web/static/js/actions/channels'
import { channel } from '../fixtures'

describe('channels reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, filter: null, items: null, order: null, sortBy: null, sortAsc: true, page: {index: 0, size: 5}})
  })

  it('should start fetching channels', () => {
    const projectId = 100
    const result = reducer(initialState, actions.startFetchingChannels(projectId))
    expect(result.fetching).toEqual(true)
  })

  it('should receive channels', () => {
    const channels = {'1': {...channel, id: 1}}
    const r1 = reducer(initialState, actions.startFetchingChannels())
    const result = reducer(r1, actions.receiveChannels(channels))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(channels)
    expect(result.order).toEqual([1])
  })

  it('should sort channels by name', () => {
    const channels = {'1': {...channel, id: 1, name: 'foo'}, '2': {...channel, id: 2, name: 'bar'}}
    const r1 = reducer(initialState, actions.startFetchingChannels())
    const r2 = reducer(r1, actions.receiveChannels(channels))
    const r3 = reducer(r2, actions.sortChannelsBy('name'))
    expect(r3.order).toEqual([2, 1])
    const r4 = reducer(r3, actions.sortChannelsBy('name'))
    expect(r4.order).toEqual([1, 2])
  })

  it('should go to next and previous page', () => {
    const r1 = reducer(initialState, actions.nextChannelsPage())
    expect(r1.page).toEqual({index: 5, size: 5})
    const r2 = reducer(r1, actions.nextChannelsPage())
    expect(r2.page).toEqual({index: 10, size: 5})
    const r3 = reducer(r2, actions.previousChannelsPage())
    expect(r3.page).toEqual({index: 5, size: 5})
  })
})
