// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/channel'
import * as actions from '../../../web/static/js/actions/channel'
import { playActionsFromState } from '../spec_helper'
import { channel } from '../fixtures'

describe('channel reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should handle initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.dirty).toEqual(false)
    expect(initialState.data).toEqual(null)
    expect(initialState.saving).toEqual(false)
    expect(initialState.filter).toEqual(null)
    expect(initialState.errors).toEqual([])
  })

  it('fetches a channel', () => {
    const state = playActions([
      actions.fetch(1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        id: 1
      },
      data: null
    })
  })

  it('receives a channel', () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel)
    ])
    expect(state.fetching).toEqual(false)
    expect(state.data).toEqual(channel)
  })

  it('creates a new pattern', () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '', 'output': ''})
  })

  it("sets pattern's input", () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern,
      actions.setInputPattern(0, '111xxx')
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '111xxx', 'output': ''})
  })

  it("sets pattern's output", () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern,
      actions.setOutputPattern(0, '222xxx')
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '', 'output': '222xxx'})
  })
})
