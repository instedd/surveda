/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/project'
import * as actions from '../../../web/static/js/actions/project'

describe('project reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, projectId: null, data: null})
  })

  it('should start fetching project', () => {
    const result = reducer(initialState, actions.startFetchingProject(1))
    expect(result).toEqual({fetching: true, projectId: 1, data: null})
  })

  it('should start fetching project when another project is being fetched', () => {
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.startFetchingProject(2))
    expect(r2).toEqual({fetching: true, projectId: 2, data: null})
  })

  it('should receive project', () => {
    const project = {id: 1}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))
    expect(r2).toEqual({fetching: false, projectId: 1, data: project})
  })

  it('should ignore receive project when fetching another project', () => {
    const project = {id: 1234}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))
    expect(r2).toEqual({fetching: true, projectId: 1, data: null})
  })

  it('should keep data when re-fetching a same project', () => {
    const project = {id: 1}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))
    const r3 = reducer(r2, actions.startFetchingProject(1))
    expect(r3).toEqual({fetching: true, projectId: 1, data: project})
  })

  it('should null data when fetching another project', () => {
    const project = {id: 1}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))
    const r3 = reducer(r2, actions.startFetchingProject(2))
    expect(r3).toEqual({fetching: true, projectId: 2, data: null})
  })

  it('should clear project', () => {
    const project = {id: 1}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))
    const r3 = reducer(r2, actions.clearProject())
    expect(r3).toEqual({fetching: false, projectId: null, data: null})
  })

  it('should update project', () => {
    const project = {id: 1, name: 'p1'}
    const r1 = reducer(initialState, actions.startFetchingProject(1))
    const r2 = reducer(r1, actions.receiveProject(project))

    const project2 = {id: 1, name: 'p2'}
    const r3 = reducer(r2, actions.updateProject(project2))
    expect(r3).toEqual({fetching: false, projectId: 1, data: project2})
  })
})
