// @flow
import * as actions from "../actions/step"

const initialState = {
  current: null,
  progress: 0.0,
  errorMessage: null,
  title: "",
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    case actions.RECEIVE:
      return receiveStep(state, action)
    default:
      return state
  }
}

const receiveStep = (state, action) => {
  // When re-fetching a step because of a window.focus() event,
  // don't change it if the step ends up being the same
  if (state.current && state.current.id == action.step.id) {
    return state
  }

  return {
    ...state,
    current: action.step,
    progress: action.progress,
    errorMessage: action.errorMessage,
    title: action.title,
  }
}
