import filter from 'lodash/filter'
import findIndex from 'lodash/findIndex'
import isEqual from 'lodash/isEqual'
import toInteger from 'lodash/toInteger'
import * as actions from '../actions/questionnaire'
import uuid from 'node-uuid'

const defaultState = {
  fetching: false,
  filter: null,
  data: null
}

export default (state, action) => {
  if (state == undefined) {
    return defaultState
  }

  switch (action.type) {
    case actions.FETCH: return fetch(state, action)
    case actions.RECEIVE: return receive(state, action)
    case actions.NEW: return newQuestionnaire(state, action)
  }

  return {
    ...state,
    data: state.data == null ? null : dataReducer(state.data, action)
  }
}

const dataReducer = (state, action) => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.TOGGLE_MODE: return toggleMode(state, action)
  }

  return {
    ...state,
    steps: stepsReducer(state.steps, action)
  }
}

const stepsReducer = (state, action) => {
  switch (action.type) {
    case actions.ADD_STEP: return addStep(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_PROMPT_SMS: return changeStepSmsPrompt(state, action)
    case actions.CHANGE_STEP_PROMPT_IVR: return changeStepIvrPrompt(state, action)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action)
  }

  return state
}

const addChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => {
    step.choices = [
      ...step.choices,
      {
        value: '',
        responses: []
      }
    ]
    return step
  })
}

const deleteChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => {
    step.choices = [
      ...step.choices.slice(0, action.index),
      ...step.choices.slice(action.index + 1)
    ]
    return step
  })
}

const changeChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => {
    step.choices = [
      ...step.choices.slice(0, action.choiceChange.index),
      {
        ...step.choices[action.choiceChange.index],
        value: action.choiceChange.value,
        responses: action.choiceChange.responses.split(',').map((r) => r.trim())
      },
      ...step.choices.slice(action.choiceChange.index + 1)
    ]
    return step
  })
}

const deleteStep = (state, action) => {
  return filter(state, s => s.id != action.stepId)
}

const changeStep = (state, stepId, func) => {
  const stepIndex = findIndex(state, s => s.id == stepId)
  return [
    ...state.slice(0, stepIndex),
    func({...state[stepIndex]}),
    ...state.slice(stepIndex + 1)
  ]
}

const changeStepSmsPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => {
    step.prompt = {
      ...step.prompt,
      sms: action.newPrompt
    }
    return step
  })
}

const changeStepIvrPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => {
    step.prompt = {
      ...step.prompt,
      ivr: action.newPrompt
    }
    return step
  })
}

const changeStepTitle = (state, action) => {
  return changeStep(state, action.stepId, step => {
    step.title = action.newTitle
    return step
  })
}

const changeStepStore = (state, action) => {
  return changeStep(state, action.stepId, step => {
    step.store = action.newStore
    return step
  })
}

const buildFilter = (projectId, questionnaireId) => ({
  projectId: toInteger(projectId),
  questionnaireId: questionnaireId == null ? null : toInteger(questionnaireId)
})

const newQuestionnaire = (state, action) => {
  return {
    ...state,
    fetching: false,
    filter: buildFilter(action.projectId, null),
    data: {
      id: null,
      name: '',
      modes: ['SMS'],
      projectId: action.projectId,
      steps: []
    }
  }
}

const addStep = (state, action) => {
  return [
    ...state,
    action.newStep
  ]
}

export const buildNewStep = (stepType) => ({
  id: uuid.v4(),
  type: stepType,
  title: '',
  store: '',
  prompt: {
    sms: ''
  },
  choices: []
})

const toggleMode = (state, action) => {
  let modes = state.modes
  if (modes.indexOf(action.mode) == -1) {
    modes = modes.slice()
    modes.push(action.mode)
  } else {
    modes = modes.filter(mode => mode != action.mode)
  }
  return {
    ...state,
    modes
  }
}

const changeName = (state, action) => {
  return {
    ...state,
    name: action.newName
  }
}

const receive = (state, action) => {
  const questionnaire = action.questionnaire
  const dataFilter = buildFilter(questionnaire.projectId, questionnaire.id)

  if (isEqual(state.filter, dataFilter)) {
    return {
      ...state,
      fetching: false,
      data: questionnaire
    }
  }

  return state
}

const fetch = (state, action) => {
  const newFilter = buildFilter(action.projectId, action.questionnaireId)

  let newData = null

  if (isEqual(state.filter, newFilter)) {
    newData = state.data
  }

  return {
    ...state,
    fetching: true,
    filter: newFilter,
    data: newData
  }
}
