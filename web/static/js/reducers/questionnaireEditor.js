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
  return {
    questionnaire: questionnaireReducer(state.questionnaire, action),
    steps: stepsReducer(state.steps, action)
  }
}

const questionnaireReducer = (state, action) => {
  switch (action.type) {
    case actions.INITIALIZE_EDITOR: return initializeQuestionnaire(state, action)
    default: return state
  }
}

const stepsReducer = (state, action) => {
  switch (action.type) {
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.INITIALIZE_EDITOR: return initializeQuestionnaireSteps(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action)
    default: return state
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

const initializeQuestionnaire = (state, action) => {
  const q = action.questionnaire
  return {
    id: q.id,
    name: q.name,
    modes: q.modes,
    projectId: q.projectId
  }
}

const initializeQuestionnaireSteps = (state, action) => {
  const q = action.questionnaire
  return {
    ...defaultState.steps,
    ids: q.steps.map(step => step.id),
    items: reduce(q.steps, reduceStepsForEditor, {})
  }
}

const reduceStepsForEditor = (items, step) => {
  items[step.id] = step
  return items
}

const addChoice = (state, action) => {
  return updateChoices(state, choices => choices.push({
    value: '',
    responses: []
  }))
}

const deleteChoice = (state, action) => {
  return updateChoices(state, choices => choices.splice(action.index, 1))
}
