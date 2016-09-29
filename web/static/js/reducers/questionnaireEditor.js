import * as actions from '../actions/questionnaireEditor'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.SELECT_STEP:
      return {
        ...state,
        currentStepId: action.stepId,
      }
    default:
      return state
  }
}
