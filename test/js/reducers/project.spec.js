/* eslint-env mocha */
import expect from 'expect'
import { playActionsFromState } from '../spec_helper'
import reducer from '../../../web/static/js/reducers/project'
import * as actions from '../../../web/static/js/actions/project'

describe('project reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, projectId: null, data: null})
  })

  it('should start fetching project', () => {
    const state = playActions([
      actions.startFetchingProject(1)
    ])
    expect(state).toEqual({fetching: true, projectId: 1, data: null})
  })

  it('should start fetching project when another project is being fetched', () => {
    const state = playActions([
      actions.startFetchingProject(1),
      actions.startFetchingProject(2)
    ])

    expect(state).toEqual({fetching: true, projectId: 2, data: null})
  })

  it('should receive project', () => {
    const project = {id: 1}
    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project)
    ])

    expect(state).toEqual({fetching: false, projectId: 1, data: project})
  })

  it('should ignore receive project when fetching another project', () => {
    const project = {id: 1234}
    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project)
    ])

    expect(state).toEqual({fetching: true, projectId: 1, data: null})
  })

  it('should keep data when re-fetching a same project', () => {
    const project = {id: 1}
    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project),
      actions.startFetchingProject(1)
    ])

    expect(state).toEqual({fetching: true, projectId: 1, data: project})
  })

  it('should null data when fetching another project', () => {
    const project = {id: 1}
    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project),
      actions.startFetchingProject(2)
    ])

    expect(state).toEqual({fetching: true, projectId: 2, data: null})
  })

  it('should clear project', () => {
    const project = {id: 1}
    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project),
      actions.clearProject()
    ])

    expect(state).toEqual({fetching: false, projectId: null, data: null})
  })

  it('should create project', () => {
    const project = {id: 1, name: 'p1'}

    const state = playActions([
      actions.createProject(project)
    ])

    expect(state).toEqual({fetching: false, projectId: 1, data: project})
  })

  it('should update project', () => {
    const project = {id: 1, name: 'p1'}
    const project2 = {id: 1, name: 'p2'}

    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project),
      actions.updateProject(project2)
    ])

    expect(state).toEqual({fetching: false, projectId: 1, data: project2})
  })

  it('should update project with colourScheme', () => {
    const project = {id: 1, name: 'p1'}
    const project2 = {id: 1, name: 'p2', colourScheme: 'default'}

    const state = playActions([
      actions.startFetchingProject(1),
      actions.receiveProject(project),
      actions.updateProject(project2)
    ])

    expect(state).toEqual({fetching: false, projectId: 1, data: project2})
  })
})
