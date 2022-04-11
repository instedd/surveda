import * as actions from "../actions/collaborators"

const initialState = {
  fetching: false,
  items: null,
  projectId: null,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_COLLABORATORS:
      return fetchCollaborators(state, action)
    case actions.RECEIVE_COLLABORATORS:
      return receiveCollaborators(state, action)
    case actions.COLLABORATOR_REMOVED:
      return collaboratorRemoved(state, action)
    case actions.COLLABORATOR_LEVEL_UPDATED:
      return collaboratorLevelUpdated(state, action)
    default:
      return state
  }
}

const receiveCollaborators = (state, action) => {
  const items = action.response.collaborators
  return {
    ...state,
    fetching: false,
    projectId: action.projectId,
    items: items,
  }
}

const fetchCollaborators = (state, action) => {
  const items = state.projectId == action.projectId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    projectId: action.projectId,
  }
}

const collaboratorRemoved = (state, action) => {
  const items = state.items
  const index = items.indexOf(action.collaborator)
  return {
    ...state,
    items: [...items.slice(0, index), ...items.slice(index + 1)],
  }
}

const collaboratorLevelUpdated = (state, action) => {
  const updatedCollaborator = {
    ...action.collaborator,
    role: action.level,
  }
  const items = state.items
  const index = items.indexOf(action.collaborator)
  return {
    ...state,
    items: [...items.slice(0, index), updatedCollaborator, ...items.slice(index + 1)],
  }
}
