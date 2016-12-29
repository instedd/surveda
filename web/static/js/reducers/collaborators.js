import * as actions from '../actions/collaborators'

const initialState = {
  fetching: false,
  items: null,
  projectId: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_COLLABORATORS: return fetchCollaborators(state, action)
    case actions.RECEIVE_COLLABORATORS: return receiveCollaborators(state, action)
    default: return state
  }
}

const receiveCollaborators = (state, action) => {
  const items = action.response.collaborators
  return {
    ...state,
    fetching: false,
    projectId: action.projectId,
    items: items
  }
}

const fetchCollaborators = (state, action) => {
  const items = state.projectId == action.projectId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    projectId: action.projectId
  }
}
