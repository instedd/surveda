import * as actions from '../actions/questionnaireEditor'

const defaultState = {
  currentStepId: null
}

export default (state = defaultState, action) => {
  switch (action.type) {
    case actions.SELECT_STEP:
      return {
        ...state,
        currentStepId: action.stepId,
      }
    case actions.DESELECT_STEP:
      return {
        ...state,
        currentStepId: null,
      }
    default:
      return state
  }
}
