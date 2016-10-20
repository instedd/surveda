/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/projects'
import * as actions from '../../../web/static/js/actions/projects'

describe('projects reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, items: null})
  })

  it('should start fetching projects', () => {
    const result = reducer(initialState, actions.startFetchingProjects())
    expect(result).toEqual({fetching: true, items: null})
  })

  it('should receive projects', () => {
    const projects = {1: {id: 1}}
    const r1 = reducer(initialState, actions.startFetchingProjects())
    const result = reducer(r1, actions.receiveProjects(projects))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(projects)
  })
})
