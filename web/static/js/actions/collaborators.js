import * as api from "../api"

export const RECEIVE_COLLABORATORS = "RECEIVE_COLLABORATORS"
export const FETCH_COLLABORATORS = "FETCH_COLLABORATORS"
export const COLLABORATOR_REMOVED = "COLLABORATOR_REMOVED"
export const COLLABORATOR_LEVEL_UPDATED = "COLLABORATOR_LEVEL_UPDATED"

export const fetchCollaborators = (projectId) => (dispatch) => {
  dispatch(startFetchingCollaborators(projectId))
  api.fetchCollaborators(projectId).then((response) => {
    dispatch(receiveCollaborators(response, projectId))
  })
}

export const removeCollaborator = (projectId, collaborator) => (dispatch) => {
  return api.removeCollaborator(projectId, collaborator.email).then((response) => {
    dispatch(collaboratorRemoved(collaborator))
  })
}

export const updateLevel = (projectId, collaborator, level) => (dispatch) => {
  return api.updateCollaboratorLevel(projectId, collaborator.email, level).then((response) => {
    dispatch(collaboratorLevelUpdated(collaborator, level))
  })
}

export const collaboratorRemoved = (collaborator) => ({
  type: COLLABORATOR_REMOVED,
  collaborator,
})

export const collaboratorLevelUpdated = (collaborator, level) => ({
  type: COLLABORATOR_LEVEL_UPDATED,
  collaborator,
  level,
})

export const receiveCollaborators = (response, projectId) => ({
  type: RECEIVE_COLLABORATORS,
  projectId,
  response,
})

export const startFetchingCollaborators = (projectId) => ({
  type: FETCH_COLLABORATORS,
  projectId,
})
