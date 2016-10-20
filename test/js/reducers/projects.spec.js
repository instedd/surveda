/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/projects'
import * as actions from '../../../web/static/js/actions/projects'

describe('projects reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, items: null, sortBy: null, sortAsc: true, page: {index: 0, size: 5}})
  })

  it('should start fetching projects', () => {
    const result = reducer(initialState, actions.startFetchingProjects())
    expect(result.fetching).toEqual(true)
  })

  it('should receive projects', () => {
    const projects = {1: {id: 1}}
    const r1 = reducer(initialState, actions.startFetchingProjects())
    const result = reducer(r1, actions.receiveProjects(projects))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(projects)
  })

  it('should go to next and previous page', () => {
    const projects = {1: {id: 1}}
    const r1 = reducer(initialState, actions.nextProjectsPage())
    expect(r1.page).toEqual({index: 5, size: 5})
    const r2 = reducer(r1, actions.nextProjectsPage())
    expect(r2.page).toEqual({index: 10, size: 5})
    const r3 = reducer(r2, actions.previousProjectsPage())
    expect(r3.page).toEqual({index: 5, size: 5})
  })
})
