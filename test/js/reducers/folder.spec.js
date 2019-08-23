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

  it('receives folders', () => {
    const state = playActions([
      actions.fetchFolders(1),
      actions.fetchedFolders(1, [folder, { ...folder, id: 2 }])
    ])
    expect(state.loading).toEqual(false)
    expect(state.folders).toEqual([folder, { ...folder, id: 2 }])
  })

  it('sets loading state when loading folders', () => {
    const state = playActions([
      actions.fetchingFolders(1)
    ])
    expect(state.loadingFetch).toEqual(true)
    expect(state.folders).toEqual(null)
  })
})
