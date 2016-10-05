import * as actions from '../actions/questionnaireEditor'
import reduce from 'lodash/reduce'

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
        },
        steps: {
          ids: action.questionnaire.steps.map(step => step.id),
          items: reduce(action.questionnaire.steps, mapStepModel, {})
        }
      }
    default:
      return state
  }
}

const mapStepModel = (items, currentStep) => {
  let responses = {}
  if (currentStep.choices) {
    responses['items'] = currentStep.choices.map((choice) => {
      var responseItem = {}
      responseItem['response'] = choice.value
      return responseItem
    })
  }
  items[currentStep.id] = {title: currentStep.title, responses: responses, id: currentStep.id}
  return items
}
