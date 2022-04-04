import * as actions from "../actions/autoSaveStatus"

const initialState = {
  updatedAt: null,
  error: false,
  saving: false,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.SAVING:
      return saving(state, action)
    case actions.SAVED:
      return saved(state, action)
    case actions.RECEIVE:
      return receive(state, action)
    case actions.ERROR:
      return error(state, action)
    default:
      return state
  }
}

const saving = (state, action) => {
  return {
    ...state,
    saving: true,
  }
}

const receive = (state, action) => {
  return {
    ...state,
    updatedAt: action.data.updatedAt,
    saving: false,
  }
}

const saved = (state, action) => {
  return {
    ...state,
    updatedAt: action.data.updatedAt,
    error: false,
    saving: false,
  }
}

const error = (state, action) => {
  return {
    ...state,
    error: true,
  }
}
