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
      const q = action.questionnaire
      return {
        ...state,
        questionnaire: {
          id: q.id,
          name: q.name
        },
        steps: {
          ids: q.steps.map(step => step.id),
          items: reduce(q.steps, reduceStepsForEditor, {})
        }
      }
    default:
      return state
  }
}

// TODO: there's a terminology disconnect between what comes from the
// server and what we use here: choice vs. response. Analyze whether
// it's ok for them to be different or we should unify the vocabulary.
const reduceStepsForEditor = (items, currentStep) => {
  let responses = {}
  if (currentStep.choices) {
    responses['items'] = currentStep.choices.map(choice => {
      return { response: choice.value }
    })
  }

  items[currentStep.id] = {
    id: currentStep.id,
    title: currentStep.title,
    responses: responses
  }

  return items
}
