import * as actions from '../actions/questionnaireEditor'
import reduce from 'lodash/reduce'
import toArray from 'lodash/toArray'
import cloneDeep from 'lodash/cloneDeep'
import uuid from 'node-uuid'

const defaultState = {
  steps: {
    ids: [],
    items: {},
    current: null
  }
}

export default (state = defaultState, action) => {
  return {
    questionnaire: questionnaireReducer(state.questionnaire, action),
    steps: stepsReducer(state.steps, action)
  }
}

export const questionnaireForServer = (questionnaireEditor) => {
  let quiz = Object.assign({}, questionnaireEditor.questionnaire)
  quiz['steps'] = toArray(questionnaireEditor.steps.items)

  return quiz
}

const questionnaireReducer = (state, action) => {
  switch (action.type) {
    case actions.CHANGE_QUESTIONNAIRE_MODES: return changeQuestionnaireModes(state, action)
    case actions.INITIALIZE_EDITOR: return initializeQuestionnaire(state, action)
    case actions.NEW_QUESTIONNAIRE: return newQuestionnaire(state, action)
    case actions.CHANGE_QUESTIONNAIRE_NAME: return changeQuestionnaireName(state, action)
    default: return state
  }
}

const stepsReducer = (state, action) => {
  switch (action.type) {
    case actions.NEW_QUESTIONNAIRE: return newQuestionnaireSteps(state, action)
    case actions.SELECT_STEP: return selectStep(state, action)
    case actions.DESELECT_STEP: return deselectStep(state, action)
    case actions.ADD_STEP: return addStep(state, action)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.EDIT_CHOICE: return editChoice(state, action)
    case actions.INITIALIZE_EDITOR: return initializeQuestionnaireSteps(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_SMS_PROMPT: return changeStepSmsPrompt(state, action)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action)
    default: return state
  }
}

const changeStepStore = (state, action) => {
  return changeStep(state, step => { step.store = action.newStore })
}

const changeStepSmsPrompt = (state, action) => {
  return changeStep(state, step => {
    step.prompt = {
      ...state.items[state.current.id].prompt,
      sms: action.newPrompt
    }
  })
}

const editChoice = (state, action) => {
  return {
    ...state,
    current: {
      ...state.current,
      currentChoice: action.index
    }
  }
}

const changeChoice = (state, action) => {
  return updateChoices(state, (choices) => {
    choices[action.choiceChange.index] = {
      ...choices[action.choiceChange.index],
      value: action.choiceChange.value,
      responses: action.choiceChange.responses.split(',').map((r) => r.trim())
    }
  })
}

const updateChoices = (state, func) => {
  var choices = state.items[state.current.id].choices.slice()
  func(choices)
  return {
    ...state,
    items: {
      ...state.items,
      [state.current.id]: {
        ...state.items[state.current.id],
        choices: choices
      }
    }
  }
}

const stepTypeDisplay = (stepType) => {
  switch (stepType) {
    case 'multiple-choice':
      return 'multiple choice'
    case 'numeric':
      return 'numeric'
    default:
      return 'question'
  }
}

export const buildNewStep = (stepType) => ({
  id: uuid.v4(),
  type: stepType,
  title: `Untitled ${stepTypeDisplay(stepType)}`,
  store: '',
  prompt: {
    sms: ''
  },
  choices: []
})

const changeQuestionnaireModes = (state, action) => {
  return {
    ...state,
    modes: action.newModes.split(',')
  }
}

const changeStep = (state, func) => {
  let newState = {
    ...state,
    items: {
      ...state.items,
      [state.current.id]: {
        ...state.items[state.current.id]
      }
    }
  }
  func(newState.items[state.current.id])
  return newState
}

const initializeQuestionnaire = (state, action) => {
  const q = action.questionnaire
  return {
    ...state,
    id: q.id,
    name: q.name,
    modes: q.modes,
    projectId: q.projectId
  }
}

const initializeQuestionnaireSteps = (state, action) => {
  const q = action.questionnaire
  return {
    ...state,
    ids: q.steps.map(step => step.id),
    items: reduce(q.steps, reduceStepsForEditor, {})
  }
}

const reduceStepsForEditor = (items, step) => {
  items[step.id] = step
  return items
}

const selectStep = (state, action) => {
  return ({
    ...state,
    current: { id: action.stepId }
  })
}

const deselectStep = (state, action) => {
  return ({
    ...state,
    current: null
  })
}

const addStep = (state, action) => {
  const newStep = buildNewStep(action.stepType)

  return {
    ...state,
    ids: state.ids.concat([newStep.id]),
    items: {
      ...state.items,
      [newStep.id]: newStep
    },
    current: { id: newStep.id }
  }
}

const deleteStep = (state, action) => {
  let ids = state.ids.filter(id => id !== state.current.id)
  let items = Object.assign({}, state.items)
  delete items[state.current.id]

  return {
    ...state,
    ids,
    items,
    current: null
  }
}

const addChoice = (state, action) => {
  return updateChoices(state, choices => choices.push({
    value: 'Untitled option',
    responses: ['Untitled', 'u']
  }))
}

const deleteChoice = (state, action) => {
  return updateChoices(state, choices => choices.splice(action.index, 1))
}

const newQuestionnaire = (state, action) => {
  return {
    ...state,
    id: null,
    name: '',
    modes: ['SMS'],
    projectId: action.projectId
  }
}

const newQuestionnaireSteps = (state, action) => {
  let steps = cloneDeep(defaultState.steps)
  let defaultStep = buildNewStep('multiple-choice')
  steps.ids.push(defaultStep.id)
  steps.items[defaultStep.id] = defaultStep
  steps.current = { id: defaultStep.id }

  return steps
}

const changeQuestionnaireName = (state, action) => {
  return {
    ...state,
    name: action.newName
  }
}

const changeStepTitle = (state, action) => {
  return changeStep(state, step => { step.title = action.newTitle })
}
