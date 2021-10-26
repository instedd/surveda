/* eslint-env mocha */
// @flow
import expect from 'expect'
import { playActionsFromState } from '../spec_helper'
import reducer from '../../../web/static/js/reducers/folder'
import * as actions from '../../../web/static/js/actions/folder'
import { folder } from '../fixtures'

describe('folder reducer', () => {
  const initialState = reducer(undefined, {})

  const playActions = playActionsFromState(initialState, reducer)

  it('receives folder', () => {
    const state = playActions([
      actions.fetching(1),
      actions.receive(1, 2, { ...folder, id: 2 })
    ])
    expect(state.fetching).toEqual(false)
    expect(state.data).toEqual({ ...folder, id: 2 })
  })

  it('sets loading state when loading folder', () => {
    const state = playActions([
      actions.fetching(1)
    ])
    expect(state.fetching).toEqual(true)
    expect(state.data).toEqual(null)
  })
})
