import * as actions from '../actions/questionnaireEditor'

const defaultState = {
  steps: {
    ids: [],
    items: {},
    current: null
  }
}

export default (state = defaultState, action) => {
  switch (action.type) {
    case actions.SELECT_STEP:
      return {
        ...state,
        currentStepId: action.stepId
      }
    case actions.DESELECT_STEP:
      return {
        ...state,
        currentStepId: null
      }
    case actions.INITIALIZE_EDITOR:
      return {
        ...state,
        questionnaire: {
          id: action.questionnaire.id,
          name: action.questionnaire.name
        }
      }
    default:
      return state
  }
}
