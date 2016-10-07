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
        steps: {
          ...state.steps,
          current: action.stepId
        }
      }
    case actions.DESELECT_STEP:
      return {
        ...state,
        steps: {
          ...state.steps,
          current: null
        }
      }
    case actions.INITIALIZE_EDITOR:
      return initializeEditor(state, action)
    case actions.NEW_QUESTIONNAIRE:
      return {
        ...state,
        questionnaire: {
          ...state.questionnaire,
          id: null,
          name: '',
          modes: ['SMS'],
          projectId: action.projectId
        }
      }
    case actions.CHANGE_QUESTIONNAIRE_NAME:
      return {
        ...state,
        questionnaire: {
          ...state.questionnaire,
          name: action.newName
        }
      }
    case actions.CHANGE_QUESTIONNAIRE_MODES:
      return changeQuestionnaireModes(state, action)
    case actions.CHANGE_STEP_TITLE:
      return {
        ...state,
        steps: {
          ...state.steps,
          items: {
            ...state.steps.items,
            [state.steps.current]: {
              ...state.steps.items[state.steps.current],
              title: action.newTitle
            }
          }
        }
      }
    default:
      return state
  }
}

const changeQuestionnaireModes = (state, action) => {
  return {
    ...state,
    questionnaire: {
      ...state.questionnaire,
      modes: action.newModes.split(',')
    }
  }
}

const initializeEditor = (state, action) => {
  const q = action.questionnaire
  return {
    ...state,
    questionnaire: {
      ...state.questionnaire,
      id: q.id,
      name: q.name,
      modes: q.modes,
      projectId: q.projectId
    },
    steps: {
      ...state.steps,
      ids: q.steps.map(step => step.id),
      items: reduce(q.steps, reduceStepsForEditor, {})
    }
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
