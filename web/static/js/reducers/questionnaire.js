// @flow
import filter from 'lodash/filter'
import findIndex from 'lodash/findIndex'
import reduce from 'lodash/reduce'
import map from 'lodash/map'
import reject from 'lodash/reject'
import concat from 'lodash/concat'
import * as actions from '../actions/questionnaire'
import uuid from 'node-uuid'
import fetchReducer from './fetch'
import { setStepPrompt, newStepPrompt, getStepPromptSms, getStepPromptIvrText,
  getPromptSms, getPromptIvr, getStepPromptIvr, getPromptIvrText, getChoiceResponseSmsJoined,
  newIvrPrompt, newRefusal } from '../step'
import { promptTextPath, choicesPath, choiceValuePath, choiceSmsResponsePath,
  choiceIvrResponsePath, msgPromptTextPath, errorsByLang } from '../questionnaireErrors'
import * as language from '../language'

const dataReducer = (state: Questionnaire, action): Questionnaire => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.TOGGLE_MODE: return toggleMode(state, action)
    case actions.ADD_LANGUAGE: return addLanguage(state, action)
    case actions.REMOVE_LANGUAGE: return removeLanguage(state, action)
    case actions.SET_DEFAULT_LANGUAGE: return setDefaultLanguage(state, action)
    case actions.SET_ACTIVE_LANGUAGE: return setActiveLanguage(state, action)
    case actions.REORDER_LANGUAGES: return reorderLanguages(state, action)
    case actions.SET_SMS_QUESTIONNAIRE_MSG: return setSmsQuestionnaireMsg(state, action)
    case actions.SET_IVR_QUESTIONNAIRE_MSG: return setIvrQuestionnaireMsg(state, action)
    case actions.AUTOCOMPLETE_SMS_QUESTIONNAIRE_MSG: return autocompleteSmsQuestionnaireMsg(state, action)
    case actions.AUTOCOMPLETE_IVR_QUESTIONNAIRE_MSG: return autocompleteIvrQuestionnaireMsg(state, action)
    case actions.UPLOAD_CSV_FOR_TRANSLATION: return uploadCsvForTranslation(state, action)
    default: return steps(state, action)
  }
}

const validateReducer = (reducer: StoreReducer<Questionnaire>): StoreReducer<Questionnaire> => {
  // React will call this with an undefined the first time for initialization.
  // We mimic that in the specs, so DataStore<Questionnaire> needs to become optional here.
  return (state: ?DataStore<Questionnaire>, action: any) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

// We don't want changing the active language to mark the questionnaire
// as dirty, which will eventually autosave it.
const dirtyPredicate = (action, oldData, newData) => {
  switch (action.type) {
    case actions.SET_ACTIVE_LANGUAGE: return false
    default: return true
  }
}

export default validateReducer(fetchReducer(actions, dataReducer, null, dirtyPredicate))

const steps = (state, action) => {
  // Up to now we've been assuming that all content was under corresponding 'en' keys,
  // now that languages can be added and removed and default language can be
  // set to whatever the user wants, that assumption is not safe anymore.
  // Moreover, most of the actions that the stepsReducer needs to handle will need
  // questionnaire level knowledge, namely the set of all questionnaire languages
  // and the questionnaire's default language.
  // Given we are on a tight schedule, I chose to pass the questionnaire down
  // to the stepsReducer in a separate variable so there are no conflicts.
  // That's the `state` argument added to the stepsReducer call.
  // Multilanguage has impacted the application much more thoroughly than we had
  // anticipated, this is a compromise solution that should be revised.
  const newSteps = state.steps == null ? [] : stepsReducer(state.steps, action, state)

  if (newSteps !== state.steps) {
    return {
      ...state,
      steps: newSteps
    }
  } else {
    return state
  }
}

const stepsReducer = (state: Step[], action, quiz: Questionnaire) => {
  switch (action.type) {
    case actions.ADD_STEP: return addStep(state, action)
    case actions.MOVE_STEP: return moveStep(state, action)
    case actions.MOVE_STEP_TO_TOP: return moveStepToTop(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_TYPE: return changeStepType(state, action)
    case actions.CHANGE_STEP_PROMPT_SMS: return changeStepSmsPrompt(state, action, quiz)
    case actions.CHANGE_STEP_PROMPT_IVR: return changeStepIvrPrompt(state, action, quiz)
    case actions.CHANGE_STEP_AUDIO_ID_IVR: return changeStepIvrAudioId(state, action, quiz)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.AUTOCOMPLETE_STEP_PROMPT_SMS: return autocompleteStepSmsPrompt(state, action, quiz)
    case actions.AUTOCOMPLETE_STEP_PROMPT_IVR: return autocompleteStepIvrPrompt(state, action, quiz)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action, quiz)
    case actions.AUTOCOMPLETE_CHOICE_SMS_VALUES: return autocompleteChoiceSmsValues(state, action, quiz)
    case actions.CHANGE_NUMERIC_RANGES: return changeNumericRanges(state, action)
    case actions.CHANGE_RANGE_SKIP_LOGIC: return changeRangeSkipLogic(state, action)
    case actions.CHANGE_EXPLANATION_STEP_SKIP_LOGIC: return changeExplanationStepSkipLogic(state, action)
    case actions.CHANGE_DISPOSITION: return changeDisposition(state, action)
    case actions.TOGGLE_ACCEPT_REFUSALS: return toggleAcceptsRefusals(state, action)
    case actions.CHANGE_REFUSAL: return changeRefusal(state, action, quiz)
  }

  return state
}

const addChoice = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    choices: [
      ...step.choices,
      {
        value: '',
        responses: {
          ivr: [],
          sms: {
            'en': []
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

const changeChoice = (state, action, quiz: Questionnaire) => {
  let response = action.choiceChange.response.trim()
  let smsValues = action.choiceChange.smsValues.trim()
  let ivrValues = action.choiceChange.ivrValues.trim()

  if (action.choiceChange.autoComplete && smsValues == '' && ivrValues == '') {
    [smsValues, ivrValues] = autoComplete(state, response, quiz)
  }

  return changeStep(state, action.stepId, (step) => {
    const previousChoices = step.choices.slice(0, action.choiceChange.index)
    const choice = step.choices[action.choiceChange.index]
    const nextChoices = step.choices.slice(action.choiceChange.index + 1)
    return ({
      ...step,
      choices: [
        ...previousChoices,
        {
          ...choice,
          value: response,
          responses: {
            ...choice.responses,
            ivr: splitValues(ivrValues),
            sms: {
              ...choice.responses.sms,
              [quiz.activeLanguage]: splitValues(smsValues)
            }
          },
          skipLogic: action.choiceChange.skipLogic
        },
        ...nextChoices
      ]
    })
  })
}

const autocompleteChoiceSmsValues = (state, action, quiz: Questionnaire) => {
  return changeStep(state, action.stepId, (step) => {
    const previousChoices = step.choices.slice(0, action.index)
    const choice = step.choices[action.index]
    const nextChoices = step.choices.slice(action.index + 1)

    let newChoice = {...choice}
    let responses = newChoice.responses
    let newResponses = {...responses}
    newChoice.responses = newResponses
    let sms = newResponses.sms
    let newSms = {...sms}
    newResponses.sms = newSms

    // First change default language
    newSms[quiz.defaultLanguage] = splitValues(action.item.text)

    // Then change other languages
    for (let translation of action.item.translations) {
      if (!translation.language) continue

      let currentSms = sms[translation.language] || []
      if (currentSms.length == 0) {
        newSms[translation.language] = splitValues(translation.text)
      }
    }

    return ({
      ...step,
      choices: [
        ...previousChoices,
        newChoice,
        ...nextChoices
      ]
    })
  })
}

const autoComplete = (state, value, quiz: Questionnaire) => {
  let setted = false

  let smsValues = ''
  let ivrValues = ''

  state.forEach((step) => {
    if ((step.type === 'multiple-choice') && !setted) {
      step.choices.forEach((choice) => {
        if (choice.value == value && !setted) {
          setted = true

          if (choice.responses.sms && choice.responses.sms[quiz.activeLanguage]) {
            smsValues = choice.responses.sms[quiz.activeLanguage].join(',')
          }

          if (choice.responses.ivr) {
            ivrValues = choice.responses.ivr.join(',')
          }
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

const moveStep = (state, action) => {
  const stepToMove = state[findIndex(state, s => s.id === action.sourceStepId)]
  const stepAbove = state[findIndex(state, s => s.id === action.targetStepId)]

  const move = (accum, step) => {
    if (step.id != stepToMove.id) {
      accum.push(step)
    }

    if (step.id === stepAbove.id) {
      accum.push(stepToMove)
    }

    return accum
  }

  return reduce(state, move, [])
}

const moveStepToTop = (state, action) => {
  const stepToMove = state[findIndex(state, s => s.id === action.stepId)]
  return concat([stepToMove], reject(state, s => s.id === action.stepId))
}

function changeStep<T: Step>(state, stepId, func: (step: Object) => T) {
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

const changeStepSmsPrompt = (state, action: ActionChangeStepSmsPrompt, quiz: Questionnaire): Step[] => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, quiz.activeLanguage, prompt => ({
      ...prompt,
      sms: action.newPrompt.trim()
    }))
  })
}

const autocompleteStepSmsPrompt = (state, action, quiz: Questionnaire): Step[] => {
  return changeStep(state, action.stepId, step => {
    // First change default language
    step = setStepPrompt(step, quiz.defaultLanguage, prompt => ({
      ...prompt,
      sms: action.item.text.trim()
    }))

    // Then change other languages
    for (let translation of action.item.translations) {
      if (!translation.language) continue

      step = setStepPrompt(step, translation.language, prompt => {
        if ((prompt || {}).sms == '') {
          return {
            ...prompt,
            sms: translation.text.trim()
          }
        } else {
          return prompt
        }
      })
    }

    return step
  })
}

const autocompleteStepIvrPrompt = (state, action, quiz: Questionnaire): Step[] => {
  return changeStep(state, action.stepId, step => {
    // First change default language
    step = setStepPrompt(step, quiz.defaultLanguage, prompt => ({
      ...prompt,
      ivr: {
        ...prompt.ivr,
        text: action.item.text.trim()
      }
    }))

    // Then change other languages
    for (let translation of action.item.translations) {
      if (!translation.language) continue

      step = setStepPrompt(step, translation.language, prompt => {
        let ivr = prompt.ivr || newIvrPrompt()
        if (ivr.text == '') {
          return {
            ...prompt,
            ivr: {
              ...ivr,
              text: translation.text.trim()
            }
          }
        } else {
          return prompt
        }
      })
    }

    return step
  })
}

const changeStepIvrPrompt = (state, action, quiz: Questionnaire) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, quiz.activeLanguage, prompt => ({
      ...prompt,
      ivr: {
        ...prompt.ivr,
        text: action.newPrompt.text.trim(),
        audioSource: action.newPrompt.audioSource
      }
    }))
  })
}

const changeStepIvrAudioId = (state, action, quiz: Questionnaire) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, quiz.activeLanguage, prompt => ({
      ...prompt,
      ivr: {
        ...prompt.ivr,
        audioId: action.newId,
        audioSource: 'upload'
      }
    }))
  })
}

const changeStepTitle = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    title: action.newTitle.trim()
  }))
}

const changeStepType = (state, action) => {
  switch (action.stepType) {
    case 'multiple-choice':
      return changeStep(state, action.stepId, step => {
        let newStep = {
          id: step.id,
          title: step.title,
          store: step.store,
          type: action.stepType,
          prompt: step.prompt,
          choices: []
        }
        return newStep
      })
    case 'numeric':
      return changeStep(state, action.stepId, step => {
        let newStep = {
          id: step.id,
          title: step.title,
          store: step.store,
          type: action.stepType,
          prompt: step.prompt,
          minValue: null,
          maxValue: null,
          rangesDelimiters: null,
          ranges: [{from: null, to: null, skipLogic: null}],
          refusal: newRefusal()
        }
        return newStep
      })
    case 'explanation':
      return changeStep(state, action.stepId, step => {
        let newStep = {
          id: step.id,
          type: action.stepType,
          title: step.title,
          prompt: step.prompt,
          skipLogic: null
        }
        return newStep
      })
    case 'flag':
      return changeStep(state, action.stepId, step => {
        let newStep = {
          id: step.id,
          type: action.stepType,
          disposition: 'partial',
          title: step.title,
          skipLogic: null
        }
        return newStep
      })
    default:
      throw new Error(`unknown step type: ${action.stepType}`)
  }
}

const changeStepStore = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    store: action.newStore.trim()
  }))
}

const addStep = (state, action) => {
  return [
    ...state,
    newMultipleChoiceStep()
  ]
}

const newLanguageSelectionStep = (first: string, second: string): LanguageSelectionStep => {
  return {
    id: uuid.v4(),
    type: 'language-selection',
    title: 'Language selection',
    store: 'language',
    prompt: newStepPrompt(),
    languageChoices: [null, first, second]
  }
}

const newMultipleChoiceStep = () => {
  return {
    id: uuid.v4(),
    type: 'multiple-choice',
    title: '',
    store: '',
    prompt: {
      'en': newStepPrompt()
    },
    choices: []
  }
}

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
    name: action.newName.trim()
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
    let newSteps = removeOptionFromLanguageSelectionStep(state, action.language)

    // If only one language remains, remove the language-selection
    // step (should be the first one)
    if (newLanguages.length == 1 && state.languages.length > 1) {
      newSteps = newSteps.slice(1)
    }

    // If the active language was removed, set it to the default language
    let activeLanguage = state.activeLanguage
    if (action.language == activeLanguage) {
      activeLanguage = state.defaultLanguage
    }

    return {
      ...state,
      steps: newSteps,
      activeLanguage,
      languages: newLanguages
    }
  } else {
    return state
  }
}

const reorderLanguages = (state, action) => {
  let languageSelectionStep = state.steps[0]

  if (languageSelectionStep.type === 'language-selection') {
    let choices = languageSelectionStep.languageChoices

    var index = choices.indexOf(action.language)
    if (index > -1) {
      choices.splice(index, 1)
      choices.splice(action.index, 0, action.language)
    }

    return {
      ...state,
      steps: changeStep(state.steps, state.steps[0].id, (step) => ({
        ...step,
        languageChoices: choices
      }))
    }
  } else {
    return state
  }
}

const setQuestionnaireMsg = (state, action, mode) => {
  let questionnaireMsg
  let activeLanguageMsg
  questionnaireMsg = Object.assign({}, state[action.msgKey])
  if (state[action.msgKey] && state[action.msgKey][state.activeLanguage]) {
    activeLanguageMsg = questionnaireMsg[state.activeLanguage]
  } else {
    activeLanguageMsg = {}
    questionnaireMsg[state.activeLanguage] = activeLanguageMsg
  }

  let msg = action.msg
  if (typeof (msg) == 'string') {
    msg = msg.trim()
  }
  if (msg.text) {
    msg.text = msg.text.trim()
  }

  activeLanguageMsg[mode] = msg
  let newState = {...state}
  newState[action.msgKey] = questionnaireMsg
  return newState
}

const setIvrQuestionnaireMsg = (state, action) => {
  return setQuestionnaireMsg(state, action, 'ivr')
}

const setSmsQuestionnaireMsg = (state, action) => {
  return setQuestionnaireMsg(state, action, 'sms')
}

const autocompleteSmsQuestionnaireMsg = (state, action) => {
  let lang = state.defaultLanguage
  let msgKey = action.msgKey
  let item = action.item
  let msg = Object.assign({}, state[msgKey])

  // First default language
  let langPrompt = msg[lang] || {}
  msg[lang] = {
    ...langPrompt,
    sms: item.text.trim()
  }

  // Now translations
  for (let translation of action.item.translations) {
    lang = translation.language
    if (!lang) continue

    let langPrompt = msg[lang] || {}
    let sms = langPrompt.sms || ''
    if (sms == '') {
      msg[lang] = {
        ...langPrompt,
        sms: translation.text.trim()
      }
    }
  }

  return {
    ...state,
    [msgKey]: msg
  }
}

const autocompleteIvrQuestionnaireMsg = (state, action) => {
  let lang = state.defaultLanguage
  let msgKey = action.msgKey
  let item = action.item
  let msg = Object.assign({}, state[msgKey])

  // First default language
  let langPrompt = msg[lang] || {}
  let ivr = langPrompt.ivr || {}
  msg[lang] = {
    ...langPrompt,
    ivr: {
      ...ivr,
      text: item.text.trim()
    }
  }

  // Now translations
  for (let translation of action.item.translations) {
    lang = translation.language
    if (!lang) continue

    let langPrompt = msg[lang] || {}
    let ivr = langPrompt.ivr || newIvrPrompt()
    let text = ivr.text || ''
    if (text == '') {
      msg[lang] = {
        ...langPrompt,
        ivr: {
          ...ivr,
          text: translation.text.trim()
        }
      }
    }
  }

  return {
    ...state,
    [msgKey]: msg
  }
}

const addOptionToLanguageSelectionStep = (state, language) => {
  return changeStep(state.steps, state.steps[0].id, (step) => ({
    ...step,
    languageChoices: [
      ...step.languageChoices,
      language
    ]
  }))
}

const removeOptionFromLanguageSelectionStep = (state, language) => {
  const languageSelectionStep = state.steps[0]

  if (languageSelectionStep.type === 'language-selection') {
    const choices = languageSelectionStep.languageChoices
    const index = choices.indexOf(language)

    const newLanguages = [...choices.slice(0, index), ...choices.slice(index + 1)]

    return changeStep(state.steps, languageSelectionStep.id, (step) => ({
      ...step,
      languageChoices: newLanguages
    }))
  } else {
    return state.steps
  }
}

const addLanguageSelectionStep = (state, action) => {
  return [
    newLanguageSelectionStep(state.languages[0], action.language),
    ...state.steps
  ]
}

const setDefaultLanguage = (state, action) => {
  return {
    ...state,
    defaultLanguage: action.language,
    activeLanguage: action.language
  }
}

const setActiveLanguage = (state, action) => {
  return {
    ...state,
    activeLanguage: action.language
  }
}

type ValidationContext = {
  sms: boolean,
  ivr: boolean,
  activeLanguage: string,
  languages: string[],
  errors: Errors
};

const validate = (state: DataStore<Questionnaire>) => {
  const data = state.data
  if (!data) return
  state.errors = {}

  const context = {
    sms: data.modes.indexOf('sms') != -1,
    ivr: data.modes.indexOf('ivr') != -1,
    activeLanguage: data.activeLanguage,
    languages: data.languages,
    errors: state.errors
  }

  validateMsg('errorMsg', data.errorMsg, context)
  validateMsg('quotaCompletedMsg', data.quotaCompletedMsg, context)

  validateSteps(data.steps, context)

  state.errorsByLang = errorsByLang(state)
}

const validateMsg = (msgKey: string, msg: Prompt, context: ValidationContext) => {
  if (context.sms) {
    context.languages.forEach(lang => {
      if (getPromptSms(msg, lang).length == 0) {
        addError(context, msgPromptTextPath(msgKey, 'sms', lang), 'SMS prompt must not be blank')
      }
    })
  }

  if (context.ivr) {
    context.languages.forEach(lang => {
      let ivr = getPromptIvr(msg, lang)
      if (isBlank(ivr.text)) {
        addError(context, msgPromptTextPath(msgKey, 'ivr', lang), 'Voice prompt must not be blank')
      }
    })
  }
}

const validateSteps = (steps, context: ValidationContext) => {
  for (let i = 0; i < steps.length; i++) {
    validateStep(steps[i], i, context)
  }
}

const validateSmsLangPrompt = (step: Step, stepIndex: number, context: ValidationContext, lang: string) => {
  if (getStepPromptSms(step, lang).length == 0) {
    addError(context, promptTextPath(stepIndex, 'sms', lang), 'SMS prompt must not be blank')
  }
}

const validateIvrLangPrompt = (step: Step, stepIndex: number, context: ValidationContext, lang: string) => {
  let ivr = getStepPromptIvr(step, lang)
  if (isBlank(ivr.text)) {
    addError(context, promptTextPath(stepIndex, 'ivr', lang), 'Voice prompt must not be blank')
  }
}

const validateStep = (step: Step, stepIndex: number, context: ValidationContext) => {
  if (step.type === 'flag') {
    return
  }
  if (context.sms) {
    context.languages.forEach(lang => validateSmsLangPrompt(step, stepIndex, context, lang))
  }

  if (context.ivr) {
    context.languages.forEach(lang => validateIvrLangPrompt(step, stepIndex, context, lang))
  }

  if (step.type === 'multiple-choice') {
    validateChoices(step.choices, stepIndex, context)
  }
}

const validateSmsResponseDuplicates = (choice: Choice, context: ValidationContext, stepIndex: number, choiceIndex: number, lang: string, otherSms) => {
  if (choice.responses.sms && choice.responses.sms[lang]) {
    for (let choiceSms of choice.responses.sms[lang]) {
      if (otherSms[lang] && otherSms[lang].includes(choiceSms)) {
        addError(context, choiceSmsResponsePath(stepIndex, choiceIndex, lang), `Value "${choiceSms}" already used in a previous response`)
      }
    }

    if (!otherSms[lang]) {
      otherSms[lang] = []
    }

    otherSms[lang].push(...choice.responses.sms[lang])
  }
}

const validateChoices = (choices: Choice[], stepIndex: number, context: ValidationContext) => {
  if (choices.length < 2) {
    addError(context, choicesPath(stepIndex), 'You should define at least two response options')
  }

  for (let i = 0; i < choices.length; i++) {
    validateChoice(choices[i], context, stepIndex, i)
  }

  const values = []
  let sms = {}
  let ivr = []

  for (let i = 0; i < choices.length; i++) {
    let choice = choices[i]
    if (values.includes(choice.value)) {
      addError(context, choiceValuePath(stepIndex, i), 'Value already used in a previous response')
    }

    if (context.sms) {
      context.languages.forEach(lang => validateSmsResponseDuplicates(choice, context, stepIndex, i, lang, sms))
    }

    if (context.ivr) {
      if (choice.responses.ivr) {
        for (let choiceIvr of choice.responses.ivr) {
          if (ivr.includes(choiceIvr)) {
            addError(context, choiceIvrResponsePath(stepIndex, i), `Value "${choiceIvr}" already used in a previous response`)
          }
        }
        ivr.push(...choice.responses.ivr)
      }
    }

    values.push(choice.value)
  }
}

const validateChoiceSmsResponse = (choice, context, stepIndex: number, choiceIndex: number, lang: string) => {
  if (choice.responses.sms &&
      choice.responses.sms[lang] &&
      choice.responses.sms[lang].length == 0) {
    addError(context, choiceSmsResponsePath(stepIndex, choiceIndex, lang), 'SMS must not be blank')
  }
}

const validateChoiceIvrResponse = (choice, context, stepIndex: number, choiceIndex: number) => {
  if (choice.responses.ivr &&
      choice.responses.ivr.length == 0) {
    addError(context, choiceIvrResponsePath(stepIndex, choiceIndex), '"Phone call" must not be blank')
  }

  if (choice.responses.ivr &&
      choice.responses.ivr.some(value => !value.match('^[0-9#*]*$'))) {
    addError(context, choiceIvrResponsePath(stepIndex, choiceIndex), '"Phone call" must only consist of single digits, "#" or "*"')
  }
}

const validateChoice = (choice: Choice, context: ValidationContext, stepIndex: number, choiceIndex: number) => {
  if (isBlank(choice.value)) {
    addError(context, choiceValuePath(stepIndex, choiceIndex), 'Response must not be blank')
  }

  if (context.sms) {
    context.languages.forEach(lang => validateChoiceSmsResponse(choice, context, stepIndex, choiceIndex, lang))
  }

  if (context.ivr) {
    validateChoiceIvrResponse(choice, context, stepIndex, choiceIndex)
  }
}

const addError = (context, path: string, error) => {
  context.errors[path] = context.errors[path] || []
  context.errors[path].push(error)
}

const isBlank = (value: string) => {
  return !value || value.trim().length == 0
}

export const stepStoreValues = (questionnaire: Questionnaire) => {
  const multipleChoiceSteps = reject(questionnaire.steps, (step) =>
    step.type == 'language-selection'
  )

  return reduce(multipleChoiceSteps, (options, step) => {
    options[step.store] = {
      type: step.type,
      values: map(step.choices, (choice) =>
        choice.value
      )
    }
    return options
  }, {})
}

export const csvForTranslation = (questionnaire: Questionnaire) => {
  const defaultLang = questionnaire.defaultLanguage
  const nonDefaultLangs = filter(questionnaire.languages, lang => lang !== defaultLang)

  // First column is the default lang, then the rest of the langs
  const headers = concat([defaultLang], nonDefaultLangs)
  let languageNames = headers.map(h => language.codeToName(h))
  let rows = [languageNames]

  // Keep a record of exported strings to avoid dups
  let exported = {}
  let context = {rows, headers, exported}

  questionnaire.steps.forEach(step => {
    if (step.type !== 'language-selection') {
      // Sms Prompt
      let defaultSms = getStepPromptSms(step, defaultLang)
      addToCsvForTranslation(defaultSms, context, lang => getStepPromptSms(step, lang))

      // Ivr Prompt
      let defaultIvr = getStepPromptIvrText(step, defaultLang)
      addToCsvForTranslation(defaultIvr, context, lang => getStepPromptIvrText(step, lang))

      // Sms Prompt. Note IVR responses shouldn't be translated because it is expected to be a digit.
      if (step.type === 'multiple-choice') {
        step.choices.forEach(choice => {
          // Response sms
          const defaultResponseSms = getChoiceResponseSmsJoined(choice, defaultLang)
          addToCsvForTranslation(defaultResponseSms, context, lang =>
            getChoiceResponseSmsJoined(choice, lang)
          )
        })
      }
    }
  })

  const q = questionnaire.quotaCompletedMsg
  if (q) {
    addMessageToCsvForTranslation(q, defaultLang, context)
  }

  const e = questionnaire.errorMsg
  if (e) {
    addMessageToCsvForTranslation(e, defaultLang, context)
  }

  return rows
}

const addMessageToCsvForTranslation = (m, defaultLang, context) => {
  let defaultSmsCompletedMsg = getPromptSms(m, defaultLang)
  addToCsvForTranslation(defaultSmsCompletedMsg, context, lang => getPromptSms(m, lang))

  let defaultIvrCompletedMsg = getPromptIvrText(m, defaultLang)
  addToCsvForTranslation(defaultIvrCompletedMsg, context, lang => getPromptIvrText(m, lang))
}

export const csvTranslationFilename = (questionnaire: Questionnaire): string => {
  const filename = (questionnaire.name || '').replace(/\W/g, '')
  return filename + '_translations.csv'
}

const addToCsvForTranslation = (text, context, func) => {
  if (text.length != 0 && !context.exported[text]) {
    context.exported[text] = true
    context.rows.push(context.headers.map(func))
  }
}

const changeNumericRanges = (state, action) => {
  return changeStep(state, action.stepId, step => {
    // validate
    let rangesDelimiters = action.rangesDelimiters
    let minValue: ?number = action.minValue ? parseInt(action.minValue) : null
    let maxValue: ?number = action.maxValue ? parseInt(action.maxValue) : null
    let values: Array<number> = []

    if (minValue != null) {
      values.push(minValue)
    }
    if (rangesDelimiters) {
      let delimiters = rangesDelimiters.split(',')
      values = values.concat(delimiters.map((e) => { return parseInt(e) }))
    }
    if (maxValue != null) {
      values.push(maxValue)
    }

    let isValid = true
    let i = 0
    while (isValid && i < values.length - 1) {
      isValid = values[i] < values[i + 1]
      i++
    }

    if (!isValid) {
      return {
        ...step,
        minValue: minValue,
        maxValue: maxValue,
        rangesDelimiters: rangesDelimiters
      }
    }

    // Just to please Flow...
    let auxValues: Array<?number> = values.map(n => n)

    // generate ranges
    if (minValue == null) {
      auxValues.unshift(null)
    }
    if (maxValue != null) {
      auxValues.pop()
    }

    let ranges = []
    for (let [i, from] of auxValues.entries()) {
      // P1. From the `for` expression above we know `0 <= i < auxValues.length`
      //
      // P2. Precondition: there may only be a null element at the 0th position of
      // `auxValues`. At the moment of writing this comment the code above satisfies
      // this assertion.
      //
      // Here we'll compute the `to` end of the current range.
      let to
      if (i == auxValues.length - 1) {
        // P3. We're at the end of the `auxValues` array, which means we're computing
        // the last range, which MUST end with `maxValue`.
        to = maxValue
      } else {
        // P4. We are not at the end of the array.
        // 4a. Because of `P4`, the `to` end of the current range is
        // the `from` in `auxValues` minus 1, so there's no overlap. Note that
        // since `i + 1 > 0` (see `P1`), `auxValues[i+1]` is guaranteed to be not null (see `P2`).
        const nextFrom = auxValues[i + 1]
        // 4b. Unfortunately, Flow can't make this sort of analysis, so we need to explicitly
        // ensure that `auxValues[i + 1]` is not null.
        if (nextFrom != null) {
          to = nextFrom - 1
        }
      }

      let prevRange = step.ranges.find((range) => {
        return range.from == from && range.to == to
      })
      if (prevRange) {
        ranges.push({...prevRange})
      } else {
        ranges.push({
          from: from,
          to: to,
          skipLogic: null
        })
      }
    }

    // be happy
    return {
      ...step,
      minValue: minValue,
      maxValue: maxValue,
      rangesDelimiters: rangesDelimiters,
      ranges: ranges
    }
  })
}

const changeRangeSkipLogic = (state, action) => {
  return changeStep(state, action.stepId, step => {
    let newRange = {
      ...step.ranges[action.rangeIndex],
      skipLogic: action.skipLogic
    }
    return {
      ...step,
      ranges: [
        ...step.ranges.slice(0, action.rangeIndex),
        newRange,
        ...step.ranges.slice(action.rangeIndex + 1)
      ]
    }
  })
}

const changeExplanationStepSkipLogic = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return {
      ...step,
      skipLogic: action.skipLogic
    }
  })
}

const changeDisposition = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return {
      ...step,
      disposition: action.disposition
    }
  })
}

const toggleAcceptsRefusals = (state, action) => {
  return changeStep(state, action.stepId, step => {
    const refusal = step.refusal || newRefusal()
    return {
      ...step,
      refusal: {
        ...refusal,
        enabled: !refusal.enabled
      }
    }
  })
}

const changeRefusal = (state, action, quiz) => {
  return changeStep(state, action.stepId, step => {
    return {
      ...step,
      refusal: {
        ...step.refusal,
        responses: {
          ivr: splitValues(action.ivrValues),
          sms: {
            ...step.refusal.responses.sms,
            [quiz.activeLanguage]: splitValues(action.smsValues)
          }
        },
        skipLogic: action.skipLogic
      }
    }
  })
}

const uploadCsvForTranslation = (state, action) => {
  // Convert CSV into a dictionary:
  // {defaultLanguageText -> {otherLanguage -> otherLanguageText}}
  const defaultLanguage = state.defaultLanguage
  const csv = action.csv

  // Replace language names with language codes
  const languageNames = csv[0]
  const languageCodes = languageNames.map(name => language.nameToCode(name.trim()))
  csv[0] = languageCodes

  const lookup = buildCsvLookup(csv, defaultLanguage)

  let newState = {...state}
  newState.steps = state.steps.map(step => translateStep(step, defaultLanguage, lookup))
  if (state.quotaCompletedMsg) {
    newState.quotaCompletedMsg = translatePrompt(state.quotaCompletedMsg, defaultLanguage, lookup)
  }
  if (state.errorMsg) {
    newState.errorMsg = translatePrompt(state.errorMsg, defaultLanguage, lookup)
  }
  return newState
}

const translateStep = (step, defaultLanguage, lookup): Step => {
  let newStep = {...step}
  if (step.type !== 'language-selection' && step.type !== 'flag') {
    newStep.prompt = translatePrompt(step.prompt, defaultLanguage, lookup)
    if (step.type === 'multiple-choice') {
      newStep.choices = translateChoices(newStep.choices, defaultLanguage, lookup)
    }
  }
  return ((newStep: any): Step)
}

const translatePrompt = (prompt, defaultLanguage, lookup): Prompt => {
  let defaultLanguagePrompt = prompt[defaultLanguage]
  if (!defaultLanguagePrompt) return prompt

  let newPrompt = {...prompt}
  let translations

  let sms = defaultLanguagePrompt.sms
  if (sms && (translations = lookup[sms])) {
    addTranslations(newPrompt, translations, 'sms')
  }

  let ivr = defaultLanguagePrompt.ivr
  if (ivr && (translations = lookup[ivr.text])) {
    for (let lang in translations) {
      const text = translations[lang]

      if (newPrompt[lang]) {
        newPrompt[lang] = {...newPrompt[lang]}
      } else {
        newPrompt[lang] = newStepPrompt()
      }

      if (!newPrompt[lang].ivr) {
        newPrompt[lang].ivr = newIvrPrompt()
      }

      // This isn't strictly necessary, but previous code
      // sometimes didn't add this default value to new prompts
      if (!newPrompt[lang].ivr.audioSource) {
        newPrompt[lang].ivr.audioSource = 'tts'
      }

      newPrompt[lang].ivr = {
        ...newPrompt[lang].ivr,
        text
      }
    }
  }

  return newPrompt
}

const addTranslations = (obj, translations, funcOrProperty) => {
  for (let lang in translations) {
    const text = translations[lang]
    if (obj[lang]) {
      obj[lang] = {...obj[lang]}
    } else {
      obj[lang] = newStepPrompt()
    }
    if (typeof (funcOrProperty) == 'function') {
      funcOrProperty(obj[lang], text)
    } else {
      obj[lang][funcOrProperty] = text
    }
  }
}

const translateChoices = (choices, defaultLanguage, lookup) => {
  return choices.map(choice => translateChoice(choice, defaultLanguage, lookup))
}

const translateChoice = (choice, defaultLanguage, lookup) => {
  let { responses } = choice
  if (!responses.sms || !responses.sms[defaultLanguage]) return choice

  let newChoice = {
    ...choice,
    responses: {...choice.responses}
  }

  const defLangResp = getChoiceResponseSmsJoined(choice, defaultLanguage)

  newChoice.responses.sms = processTranslations(defLangResp, newChoice.responses.sms || {}, lookup)

  return newChoice
}

const processTranslations = (value, obj, lookup, funcOrProperty) => {
  let translations
  if (value && (translations = lookup[value])) {
    for (let lang in translations) {
      obj = {
        ...obj,
        [lang]: translations[lang].split(',').map(s => s.trim())
      }
    }
  }
  return obj
}

// Converts a CSV into a dictionary:
// {defaultLanguageText -> {otherLanguage -> otherLanguageText}}
const buildCsvLookup = (csv, defaultLanguage) => {
  const lookup = {}
  const headers = csv[0]
  const defaultLanguageIndex = headers.indexOf(defaultLanguage)

  for (let i = 1; i < csv.length; i++) {
    const row = csv[i]
    let defaultLanguageText = row[defaultLanguageIndex]
    if (!defaultLanguageText || defaultLanguageText.trim().length == 0) {
      continue
    }

    defaultLanguageText = defaultLanguageText.trim()

    for (let j = 0; j < headers.length; j++) {
      if (j == defaultLanguageIndex) continue

      const otherLanguage = headers[j]
      const otherLanguageText = row[j]

      if (!otherLanguageText || otherLanguageText.trim().length == 0) {
        continue
      }

      if (!lookup[defaultLanguageText]) {
        lookup[defaultLanguageText] = {}
      }

      lookup[defaultLanguageText][otherLanguage] = otherLanguageText.trim()
    }
  }

  return lookup
}
