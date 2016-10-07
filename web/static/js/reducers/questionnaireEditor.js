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
    case actions.ADD_STEP:
      return {
        ...state,
        steps: {
          ...state.steps,
          ids: state.steps.ids.concat([action.step.id]),
          items: {
            ...state.steps.items,
            [action.step.id]: action.step
          },
          current: action.step.id
        }
      }
    case actions.DELETE_STEP:
      let ids = state.steps.ids.filter(id => id != state.steps.current)
      let items = Object.assign({}, state.steps.items)
      delete items[state.steps.current]

      return {
        ...state,
        steps: {
          ...state.steps,
          ids,
          items,
          current: null,
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

const reduceStepsForEditor = (items, currentStep) => {
  items[currentStep.id] = currentStep
  return items
}
