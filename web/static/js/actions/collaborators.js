import * as api from '../api'

export const RECEIVE_COLLABORATORS = 'RECEIVE_COLLABORATORS'
export const FETCH_COLLABORATORS = 'FETCH_COLLABORATORS'

export const fetchCollaborators = (projectId) => dispatch => {
  dispatch(startFetchingCollaborators(projectId))
  api.fetchCollaborators(projectId)
    .then(response => {
      dispatch(receiveCollaborators(response, projectId))
    })
}

export const receiveCollaborators = (response, projectId) => ({
  type: RECEIVE_COLLABORATORS,
  projectId,
  response
})

export const startFetchingCollaborators = (projectId) => ({
  type: FETCH_COLLABORATORS,
  projectId
})
