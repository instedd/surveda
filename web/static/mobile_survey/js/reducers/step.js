import * as actions from '../actions/step'

const initialState = {
  current: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.RECEIVE: return receiveStep(state, action)
    default: return state
  }
}

const receiveStep = (state, action) => {
  return {
    ...state,
    current: action.step
  }
}
