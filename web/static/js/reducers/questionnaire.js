// @flow
import filter from 'lodash/filter'
import findIndex from 'lodash/findIndex'

import * as actions from '../actions/questionnaire'
import uuid from 'node-uuid'
import fetchReducer from './fetch'

const dataReducer = (state: Questionnaire, action): Questionnaire => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.TOGGLE_MODE: return toggleMode(state, action)
    case actions.ADD_LANGUAGE: return addLanguage(state, action)
    case actions.REMOVE_LANGUAGE: return removeLanguage(state, action)
    case actions.SET_DEFAULT_LANGUAGE: return setDefaultLanguage(state, action)
    case actions.REORDER_LANGUAGES: return reorderLanguages(state, action)
    default: return steps(state, action)
  }
}

const steps = (state, action) => {
  const newSteps = state.steps == null ? [] : stepsReducer(state.steps, action)

  if (newSteps !== state.steps) {
    return {
      ...state,
      steps: newSteps
    }
  } else {
    return state
  }
}

const stepsReducer = (state, action) => {
  switch (action.type) {
    case actions.ADD_STEP: return addStep(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_TYPE: return changeStepType(state, action)
    case actions.CHANGE_STEP_PROMPT_SMS: return changeStepSmsPrompt(state, action)
    case actions.CHANGE_STEP_PROMPT_IVR: return changeStepIvrPrompt(state, action)
    case actions.CHANGE_STEP_AUDIO_ID_IVR: return changeStepIvrAudioId(state, action)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action)
  }

  return state
}

const addChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => ({
    ...step,
    choices: [
      ...step.choices,
      {
        value: '',
        responses: {
          'en': {
            sms: [],
            ivr: []
          }
        },
        skipLogic: null
      }
    ]
  }))
}

const deleteChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => ({
    ...step,
    choices: [
      ...step.choices.slice(0, action.index),
      ...step.choices.slice(action.index + 1)
    ]
  }))
}

const changeChoice = (state, action) => {
  let smsValues = action.choiceChange.smsValues
  let ivrValues = action.choiceChange.ivrValues
  if (action.choiceChange.autoComplete && smsValues == '' && ivrValues == '') {
    [smsValues, ivrValues] = autoComplete(state, action.choiceChange.response)
  }
  let ivrArrayValues = splitValues(ivrValues)
  return changeStep(state, action.stepId, (step) => ({
    ...step,
    choices: [
      ...step.choices.slice(0, action.choiceChange.index),
      {
        ...step.choices[action.choiceChange.index],
        value: action.choiceChange.response,
        responses: {
          ...step.choices[action.choiceChange.index].responses,
          'en': {
            ...step.choices[action.choiceChange.index].responses['en'],
            sms: splitValues(smsValues),
            ivr: ivrArrayValues
          }
        },
        skipLogic: action.choiceChange.skipLogic
      },
      ...step.choices.slice(action.choiceChange.index + 1)
    ]
  }))
}

const autoComplete = (state, value) => {
  let setted = false

  let smsValues = ''
  let ivrValues = ''

  state.forEach((step) => {
    if (!setted) {
      step.choices.forEach((choice) => {
        if (choice.value == value && !setted) {
          setted = true
          smsValues = choice.responses['en'].sms.join(',')
          ivrValues = choice.responses['en'].ivr.join(',')
        }
      })
    }
  })
  return [smsValues, ivrValues]
}

const splitValues = (values) => {
  return values.split(',').map((r) => r.trim()).filter(r => r.length != 0)
}

const deleteStep = (state, action) => {
  return filter(state, s => s.id != action.stepId)
}

const changeStep = (state, stepId, func: (step: Step) => Step) => {
  const stepIndex = findIndex(state, s => s.id == stepId)
  return [
    ...state.slice(0, stepIndex),
    func(state[stepIndex]),
    ...state.slice(stepIndex + 1)
  ]
}

type ActionChangeStepSmsPrompt = {
  stepId: string,
  newPrompt: string
};

const changeStepSmsPrompt = (state, action: ActionChangeStepSmsPrompt) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      'en': {
        ...step.prompt['en'],
        sms: action.newPrompt
      }
    }
  }))
}

const changeStepIvrPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      'en': {
        ...step.prompt['en'],
        ivr: {
          ...step.prompt['en'].ivr,
          text: action.newPrompt.text,
          audioSource: action.newPrompt.audioSource
        }
      }
    }
  }))
}

const changeStepIvrAudioId = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      'en': {
        ...step.prompt['en'],
        ivr: {
          ...step.prompt['en'].ivr,
          audioId: action.newId,
          audioSource: 'upload'
        }
      }
    }
  }))
}

const changeStepTitle = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    title: action.newTitle
  }))
}

const changeStepType = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    type: action.stepType,
    choices: []
  }))
}

const changeStepStore = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    store: action.newStore
  }))
}

const addStep = (state, action) => {
  return [
    ...state,
    newStep()
  ]
}

const newStep = () => ({
  id: uuid.v4(),
  type: 'multiple-choice',
  title: '',
  store: '',
  prompt: {
    'en': {
      sms: '',
      ivr: {
        text: '',
        audioSource: 'tts'
      }
    }
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

type ActionChangeName = {
  newName: string
};

const changeName = (state: Questionnaire, action: ActionChangeName): Questionnaire => {
  return {
    ...state,
    name: action.newName
  }
}

const addLanguage = (state, action) => {
  if (state.languages.indexOf(action.language) == -1) {
    let steps
    if (state.languages.length == 1) {
      steps = addLanguageSelectionStep(state, action)
    } else {
      steps = addOptionToLanguageSelectionStep(state, action.language)
    }
    return {
      ...state,
      steps: steps,
      languages: [...state.languages, action.language]
    }
  } else {
    return state
  }
}

const removeLanguage = (state, action) => {
  const indexToDelete = state.languages.indexOf(action.language)
  if (indexToDelete != -1) {
    const newLanguages = [...state.languages.slice(0, indexToDelete), ...state.languages.slice(indexToDelete + 1)]
    return {
      ...state,
      steps: removeOptionFromLanguageSelectionStep(state, action.language),
      languages: newLanguages
    }
  } else {
    return state
  }
}

const reorderLanguages = (state, action) => {
  let choices = state.steps[0].choices

  var index = choices.indexOf(action.language)
  if (index > -1) {
    choices.splice(index, 1)
    choices.splice(action.index, 0, action.language)
  }

  return {
    ...state,
    steps: changeStep(state.steps, state.steps[0].id, (step) => ({
      ...step,
      choices: choices
    }))
  }
}

const addOptionToLanguageSelectionStep = (state, language) => {
  return changeStep(state.steps, state.steps[0].id, (step) => ({
    ...step,
    choices: [
      ...step.choices,
      language
    ]
  }))
}

const removeOptionFromLanguageSelectionStep = (state, language) => {
  let choices = state.steps[0].choices
  var index = choices.indexOf(language)

  const newLanguages = [...choices.slice(0, index), ...choices.slice(index + 1)]

  return changeStep(state.steps, state.steps[0].id, (step) => ({
    ...step,
    choices: newLanguages
  }))
}

const addLanguageSelectionStep = (state, action) => {
  return [
    newLanguageSelectionStep(state.languages[0], action.language),
    ...state.steps
  ]
}

const newLanguageSelectionStep = (first, second) => {
  var step = newStep()
  step.type = 'language-selection'
  step.choices = [null, first, second]
  step.title = 'Language selection'

  return step
}

const setDefaultLanguage = (state, action) => {
  return {
    ...state,
    defaultLanguage: action.language
  }
}

type ValidationState = {
  data: Questionnaire,
  errors: { [path: string]: string[] }
};

const validateReducer = (reducer) => {
  return (state: ValidationState, action: any) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

const validate = (state: ValidationState) => {
  if (!state.data) return
  state.errors = {}
  const context = {
    sms: state.data.modes.indexOf('sms') != -1,
    ivr: state.data.modes.indexOf('ivr') != -1,
    errors: state.errors
  }

  validateSteps('steps', state.data.steps, context)
}

const validateSteps = (path, steps, context) => {
  for (let i = 0; i < steps.length; i++) {
    validateStep(`${path}[${i}]`, steps[i], context)
  }
}

const validateStep = (path, step, context) => {
  if (context.sms && isBlank(step.prompt['en'].sms)) {
    addError(context, `${path}.prompt.sms`, 'SMS prompt must not be blank')
  }

  if (context.ivr && step.prompt['en'].ivr && step.prompt['en'].ivr.audioSource == 'tts' && isBlank(step.prompt['en'].ivr.text)) {
    addError(context, `${path}.prompt.ivr.text`, 'Voice prompt must not be blank')
  }

  if (step.type == 'multiple-choice') {
    validateChoices(`${path}.choices`, step.choices, context)
  }
}

const validateChoices = (path, choices, context) => {
  if (choices.length < 2) {
    addError(context, path, 'Must have at least two responses')
  }

  for (let i = 0; i < choices.length; i++) {
    validateChoice(`${path}[${i}]`, choices[i], context)
  }

  const values = []
  let sms = []
  let ivr = []
  for (let i = 0; i < choices.length; i++) {
    let choice = choices[i]
    if (values.includes(choice.value)) {
      addError(context, `${path}[${i}].value`, 'Value already used in a previous response')
    }
    for (let choiceSms of choice.responses['en'].sms) {
      if (sms.includes(choiceSms)) {
        addError(context, `${path}[${i}].sms`, `Value "${choiceSms}" already used in a previous response`)
      }
    }
    for (let choiceIvr of choice.responses['en'].ivr) {
      if (ivr.includes(choiceIvr)) {
        addError(context, `${path}[${i}].ivr`, `Value "${choiceIvr}" already used in a previous response`)
      }
    }
    values.push(choice.value)
    sms.push(...choice.responses['en'].sms)
    ivr.push(...choice.responses['en'].ivr)
  }
}

const validateChoice = (path, choice, context) => {
  if (isBlank(choice.value)) {
    addError(context, `${path}.value`, 'Response must not be blank')
  }

  if (context.sms && choice.responses['en'].sms.length == 0) {
    addError(context, `${path}.sms`, 'SMS must not be blank')
  }

  if (context.ivr) {
    if (choice.responses['en'].ivr.length == 0) {
      addError(context, `${path}.ivr`, '"Phone call" must not be blank')
    }

    if (choice.responses['en'].ivr.some(value => !value.match('^[0-9#*]*$'))) {
      addError(context, `${path}.ivr`, '"Phone call" must only consist of single digits, "#" or "*"')
    }
  }
}

const addError = (context, path, error) => {
  context.errors[path] = context.errors[path] || []
  context.errors[path].push(error)
}

const isBlank = (value: string) => {
  return !value || value.trim().length == 0
}

export default validateReducer(fetchReducer(actions, dataReducer))
