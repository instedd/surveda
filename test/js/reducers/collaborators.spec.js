/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/collaborators'
import * as actions from '../../../web/static/js/actions/collaborators'

describe('collaborators reducer', () => {
  const initialState = reducer(undefined, {})

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
      'collaborators': [{'email': 'user@instedd.com.ar', 'level': 'owner'}]
    }
    const r1 = reducer(initialState, actions.startFetchingCollaborators(projectId))
    const result = reducer(r1, actions.receiveCollaborators(params, projectId))
    console.log(result)
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(params.collaborators)
    expect(result.projectId).toEqual(projectId)
  })
})
