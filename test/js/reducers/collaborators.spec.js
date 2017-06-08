/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/collaborators'
import * as actions from '../../../web/static/js/actions/collaborators'
import { playActionsFromState } from '../spec_helper'

describe('collaborators reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, projectId: null, items: null})
  })

  it('should start fetching collaborators', () => {
    const projectId = 11
    const result = reducer(initialState, actions.startFetchingCollaborators(projectId))
    expect(result.fetching).toEqual(true)
    expect(result.projectId).toEqual(projectId)
    expect(result.items).toEqual(null)
  })

  it('should receive respondents', () => {
    const projectId = 11
    const params = {
      'collaborators': [{'email': 'user@instedd.org.ar', 'role': 'owner'}]
    }
    const r1 = reducer(initialState, actions.startFetchingCollaborators(projectId))
    const result = reducer(r1, actions.receiveCollaborators(params, projectId))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(params.collaborators)
    expect(result.projectId).toEqual(projectId)
  })

  it('should remove collaborator', () => {
    const projectId = 11
    const c1 = {'email': 'user1@instedd.org.ar', 'role': 'owner'}
    const c2 = {'email': 'user2@instedd.org.ar', 'role': 'reader'}
    const c3 = {'email': 'user3@instedd.org.ar', 'role': 'editor'}
    const collaborators = {
      'collaborators': [c1, c2, c3]
    }
    const result = playActions([
      actions.receiveCollaborators(collaborators, projectId),
      actions.collaboratorRemoved(c2)
    ])
    expect(result.items).toEqual([c1, c3])
  })

  it('should update level of collaborator', () => {
    const projectId = 11
    const c1 = {'email': 'user1@instedd.org.ar', 'role': 'owner'}
    const c2 = {'email': 'user2@instedd.org.ar', 'role': 'reader'}
    const collaborators = {
      'collaborators': [c1, c2]
    }
    const result = playActions([
      actions.receiveCollaborators(collaborators, projectId),
      actions.collaboratorLevelUpdated(c2, 'editor')
    ])
    expect(result.items[1].role).toEqual('editor')
  })
})
