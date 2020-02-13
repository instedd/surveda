// @flow
import filter from 'lodash/filter'
import findIndex from 'lodash/findIndex'
import reduce from 'lodash/reduce'
import map from 'lodash/map'
import reject from 'lodash/reject'
import concat from 'lodash/concat'
import * as actions from '../actions/questionnaire'
import uuidv4 from 'uuid/v4'
import fetchReducer from './fetch'
import { setStepPrompt, newStepPrompt, getStepPromptSms, getStepPromptIvrText,
  getPromptSms, getPromptMobileWeb, getStepPromptMobileWeb, getPromptIvrText, getChoiceResponseSmsJoined,
  getChoiceResponseMobileWebJoined, newIvrPrompt, newRefusal } from '../step'
import * as language from '../language'
import { validate } from './questionnaire.validation'
import { defaultActiveMode } from '../questionnaire.mode'
import undoReducer from './undo'

const dataReducer = (state: Questionnaire, action): Questionnaire => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.CHANGE_DESCRIPTION: return changeDescription(state, action)
    case actions.SET_ACTIVE_MODE: return setActiveMode(state, action)
    case actions.ADD_MODE: return addMode(state, action)
    case actions.REMOVE_MODE: return removeMode(state, action)
    case actions.TOGGLE_QUOTA_COMPLETED_STEPS: return toggleQuotaCompletedSteps(state, action)
    case actions.ADD_LANGUAGE: return addLanguage(state, action)
    case actions.REMOVE_LANGUAGE: return removeLanguage(state, action)
    case actions.SET_DEFAULT_LANGUAGE: return setDefaultLanguage(state, action)
    case actions.SET_ACTIVE_LANGUAGE: return setActiveLanguage(state, action)
    case actions.REORDER_LANGUAGES: return reorderLanguages(state, action)
    case actions.SET_SMS_QUESTIONNAIRE_MSG: return setSmsQuestionnaireMsg(state, action)
    case actions.SET_IVR_QUESTIONNAIRE_MSG: return setIvrQuestionnaireMsg(state, action)
    case actions.SET_MOBILE_WEB_QUESTIONNAIRE_MSG: return setMobileWebQuestionnaireMsg(state, action)
    case actions.AUTOCOMPLETE_SMS_QUESTIONNAIRE_MSG: return autocompleteSmsQuestionnaireMsg(state, action)
    case actions.AUTOCOMPLETE_IVR_QUESTIONNAIRE_MSG: return autocompleteIvrQuestionnaireMsg(state, action)
    case actions.UPLOAD_CSV_FOR_TRANSLATION: return uploadCsvForTranslation(state, action)
    case actions.SET_MOBILE_WEB_SETTING_TEXT: return setMobileWebSettingText(state, action)
    case actions.SET_MOBILE_WEB_SURVEY_IS_OVER_MESSAGE: return setMobileWebSurveyIsOverMessage(state, action)
    case actions.SET_PRIMARY_COLOR: return setPrimaryColor(state, action)
    case actions.SET_SECONDARY_COLOR: return setSecondaryColor(state, action)
    case actions.SET_DISPLAYED_TITLE: return setDisplayedTitle(state, action)
    case actions.SET_SURVEY_ALREADY_TAKEN_MESSAGE: return setSurveyAlreadyTakenMessage(state, action)
    case actions.ADD_STEP: return addStep(state, action)
    case actions.ADD_STEP_TO_SECTION: return addStepToSection(state, action)
    case actions.ADD_QUOTA_COMPLETED_STEP: return addQuotaCompletedStep(state, action)
    case actions.MOVE_STEP: return moveStep(state, action)
    case actions.MOVE_SECTION: return moveSection(state, action)
    case actions.MOVE_STEP_TO_TOP: return moveStepToTop(state, action)
    case actions.MOVE_STEP_TO_TOP_OF_SECTION: return moveStepToTopOfSection(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_TYPE: return changeStepType(state, action)
    case actions.CHANGE_STEP_PROMPT_SMS: return changeStepSmsPrompt(state, action)
    case actions.CHANGE_STEP_PROMPT_IVR: return changeStepIvrPrompt(state, action)
    case actions.CHANGE_STEP_PROMPT_MOBILE_WEB: return changeStepMobileWebPrompt(state, action)
    case actions.CHANGE_STEP_AUDIO_ID_IVR: return changeStepIvrAudioId(state, action)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.AUTOCOMPLETE_STEP_PROMPT_SMS: return autocompleteStepSmsPrompt(state, action)
    case actions.AUTOCOMPLETE_STEP_PROMPT_IVR: return autocompleteStepIvrPrompt(state, action)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.DELETE_SECTION: return deleteSection(state, action)
    case actions.CHANGE_SECTION_TITLE: return changeSectionTitle(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action)
    case actions.AUTOCOMPLETE_CHOICE_SMS_VALUES: return autocompleteChoiceSmsValues(state, action)
    case actions.CHANGE_NUMERIC_RANGES: return changeNumericRanges(state, action)
    case actions.CHANGE_RANGE_SKIP_LOGIC: return changeRangeSkipLogic(state, action)
    case actions.CHANGE_EXPLANATION_STEP_SKIP_LOGIC: return changeExplanationStepSkipLogic(state, action)
    case actions.CHANGE_DISPOSITION: return changeDisposition(state, action)
    case actions.TOGGLE_ACCEPT_REFUSALS: return toggleAcceptsRefusals(state, action)
    case actions.TOGGLE_ACCEPTS_ALPHABETICAL_ANSWERS: return toggleAcceptsAlphabeticalAnswers(state, action)
    case actions.CHANGE_REFUSAL: return changeRefusal(state, action)
    case actions.SET_DIRTY: return setDirty(state)
    case actions.ADD_SECTION: return addSection(state)
    case actions.TOGGLE_RANDOMIZE_FOR_SECTION: return toggleRandomizeForSection(state, action)
    default: return state
  }
}

const validateReducer = (reducer: StoreReducer<Questionnaire>): StoreReducer<Questionnaire> => {
  // React will call this with an undefined the first time for initialization.
  // We mimic that in the specs, so DataStore<Questionnaire> needs to become optional here.
  return (state: ?DataStore<Questionnaire>, action: any) => {
    const oldData = state ? state.data : null
    const newState = reducer(state, action)

    if ((newState.data && oldData !== newState.data) || action.type == actions.UNDO || action.type == actions.REDO) {
      validate(newState)
      return {
        ...newState,
        data: {
          ...newState.data,
          valid: newState.errors.length == 0
        }
      }
    }

    return newState
  }
}

// We don't want changing the active language to mark the questionnaire
// as dirty, which will eventually autosave it.
const dirtyPredicate = (action, oldData, newData) => {
  switch (action.type) {
    case actions.SET_ACTIVE_LANGUAGE: return false
    case actions.SET_ACTIVE_MODE: return false
    default: return true
  }
}

export default (undoReducer(actions, dirtyPredicate, validateReducer(fetchReducer(actions, dataReducer, null, dirtyPredicate))): UndoReducer<Questionnaire>)

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

const changeChoice = (state, action) => {
  let response = action.choiceChange.response.trim()
  let smsValues = action.choiceChange.smsValues.trim()
  let ivrValues = action.choiceChange.ivrValues.trim()
  let mobilewebValues = action.choiceChange.mobilewebValues.trim()

  if (action.choiceChange.autoComplete && smsValues == '' && ivrValues == '') {
    [smsValues, ivrValues, mobilewebValues] = autoComplete(state.steps, state.activeLanguage, response)
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
              [state.activeLanguage]: splitValues(smsValues)
            },
            mobileweb: {
              ...choice.responses.mobileweb,
              [state.activeLanguage]: mobilewebValues
            }
          },
          skipLogic: action.choiceChange.skipLogic
        },
        ...nextChoices
      ]
    })
  })
}

const autocompleteChoiceSmsValues = (state, action) => {
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
    newSms[state.defaultLanguage] = splitValues(action.item.text)

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

const autoComplete = (steps, activeLanguage, value) => {
  let setted = false

  let smsValues = ''
  let ivrValues = ''
  let mobilewebValues = ''

  steps.forEach((step) => {
    if (!setted) {
      if ((step.type === 'multiple-choice')) {
        step.choices.forEach((choice) => {
          if (choice.value.toLowerCase() == value.toLowerCase() && !setted) {
            setted = true

            if (choice.responses.sms && choice.responses.sms[activeLanguage]) {
              smsValues = choice.responses.sms[activeLanguage].join(',')
            }

            if (choice.responses.ivr) {
              ivrValues = choice.responses.ivr.join(',')
            }

            if (choice.responses.mobileweb && choice.responses.mobileweb[activeLanguage]) {
              mobilewebValues = choice.responses.mobileweb[activeLanguage]
            }
          }
        })
      } else if (step.type === 'section') {
        // Recursive call to autoComplete function when step is a section
        [smsValues, ivrValues, mobilewebValues] = autoComplete(step.steps, activeLanguage, value)
        if (smsValues !== '' || ivrValues !== '' || mobilewebValues !== '') {
          setted = true
        }
      }
    }
  })
  return [smsValues, ivrValues, mobilewebValues]
}

const splitValues = (values) => {
  return values.split(',').map((r) => r.trim()).filter(r => r.length != 0)
}

const deleteStep = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return {
      ...step,
      delete: true
    }
  })
}

const deleteSection = (state, action) => {
  const section = state.steps.find(s => s.id == action.sectionId)
  const filteredSteps = filter(state.steps, s => s.id != action.sectionId)

  if (hasSections(filteredSteps)) {
    return {
      ...state,
      steps: filteredSteps
    }
  } else {
    if (section && section.type === 'section') {
      return {
        ...state,
        steps: [
          ...filteredSteps,
          ...section.steps
        ]
      }
    } else {
      return state
    }
  }
}

const changeSectionTitle = (state, action) => {
  return findAndUpdateRegularStep(state.steps, action.sectionId, state, section => {
    if (section && section.type === 'section') {
      return {
        ...section,
        title: action.newTitle.trim()
      }
    }
    return section
  }, 'steps') || state
}

const moveSection = (state, action) => {
  const reorderSections = (sections, sourceId, targetId) => {
    if (sourceId == targetId) return sections

    let reordered = [ ...sections ]
    const languageIndex = reordered.findIndex(s => s.type == 'language-selection')
    const language = (languageIndex > -1 && reordered.splice(languageIndex, 1)) || []
    const sourceIndex = reordered.findIndex(s => s.id == sourceId)
    const source = reordered.splice(sourceIndex, 1)
    const insertIndex = targetId == 0 ? 0 : reordered.findIndex(s => s.id == targetId) + 1

    return [...language, ...reordered.slice(0, insertIndex), ...source, ...reordered.slice(insertIndex)]
  }

  const { steps: sections } = state
  const { sourceSectionId, targetSectionId } = action

  return {
    ...state,
    steps: reorderSections(sections, sourceSectionId, targetSectionId)
  }
}

const moveStep = (state, action) => {
  const move = (accum, step) => {
    if (step.id != action.sourceStepId) {
      accum.push(step)
    }

    if (step.id === action.targetStepId) {
      accum.push(stepToMove)
    }

    return accum
  }

  // First try with 'quotaCompletedSteps'
  let steps = state.quotaCompletedSteps
  let stepToMove = null
  let stepAbove = null

  if (steps) {
    stepToMove = steps[findIndex(steps, s => s.id === action.sourceStepId)]
    stepAbove = steps[findIndex(steps, s => s.id === action.targetStepId)]
    if (stepToMove && stepAbove) {
      return {
        ...state,
        quotaCompletedSteps: reduce(steps, move, [])
      }
    }
  }

  // Otherwise we try with 'steps'
  steps = state.steps

  if (hasSections(steps)) {
    let indexes = findStepAndSectionIndex(action.sourceStepId, steps)

    let sourceSectionIndex = indexes[0]
    let sourceStepIndex = indexes[1]

    if (sourceSectionIndex != null && sourceStepIndex != null) {
      stepToMove = steps[sourceSectionIndex].steps[sourceStepIndex]

      let finalSteps = removeStepFromSection(steps, action.sourceStepId, sourceSectionIndex)

      let indexes2 = findStepAndSectionIndex(action.targetStepId, finalSteps)

      let targetSectionIndex = indexes2[0]
      let targetStepIndex = indexes2[1]

      if (targetSectionIndex != null && targetStepIndex != null) {
        stepAbove = finalSteps[targetSectionIndex].steps[targetStepIndex]

        const sectionStep2 = finalSteps[targetSectionIndex]
        const sectionSteps2 = sectionStep2.steps

        finalSteps = [
          ...finalSteps.slice(0, targetSectionIndex),
          {
            ...sectionStep2,
            steps: [
              ...sectionSteps2.slice(0, targetStepIndex),
              stepAbove,
              stepToMove,
              ...sectionSteps2.slice(targetStepIndex + 1)
            ]
          },
          ...finalSteps.slice(targetSectionIndex + 1)
        ]

        return {
          ...state,
          steps: finalSteps
        }
      }
    }
  } else {
    stepToMove = steps[findIndex(steps, s => s.id === action.sourceStepId)]
    stepAbove = steps[findIndex(steps, s => s.id === action.targetStepId)]

    if (stepToMove && stepAbove) {
      return {
        ...state,
        steps: reduce(steps, move, [])
      }
    }
  }
  // If none of the above worked, it probably means one step was dragged
  // from 'steps' to 'quotaCompletedSteps' or the other way around,
  // and we don't care about that case
  return state
}

function removeStepFromSection(steps, stepId, sectionIndex) {
  const section = steps[sectionIndex]
  if (section.type === 'section') {
    return [
      ...steps.slice(0, sectionIndex),
      {
        ...section,
        steps: section.steps.filter(x => x.id !== stepId)
      },
      ...steps.slice(sectionIndex + 1)
    ]
  }
  return steps
}

const moveStepToTop = (state, action) => {
  // First try with 'quotaCompletedSteps'
  let steps = state.quotaCompletedSteps
  let stepToMove = null
  if (steps) {
    stepToMove = steps[findIndex(steps, s => s.id === action.stepId)]
    if (stepToMove) {
      return {
        ...state,
        quotaCompletedSteps: concat([stepToMove], reject(steps, s => s.id === action.stepId))
      }
    }
  }

  // Otherwise try with 'steps'
  steps = state.steps
  if (!hasSections(steps)) {
    stepToMove = steps[findIndex(steps, s => s.id === action.stepId)]
    if (stepToMove) {
      return {
        ...state,
        steps: concat([stepToMove], reject(steps, s => s.id === action.stepId))
      }
    }
  } else {
    return state
  }

  throw new Error(`Couldn't move step ${action.stepId} to the top`)
}

const moveStepToTopOfSection = (state, action) => {
  let steps = state.steps
  let indexes = findStepAndSectionIndex(action.stepId, steps)

  let sourceSectionIndex = indexes[0]
  let sourceStepIndex = indexes[1]

  if (sourceSectionIndex !== null) {
    let stepToMove = steps[sourceSectionIndex].steps[sourceStepIndex]
    let finalSteps = removeStepFromSection(steps, action.stepId, sourceSectionIndex)

    let sectionIndex = findIndex(steps, s => s.id === action.sectionId)

    let sectionStep = finalSteps[sectionIndex]

    if (sectionStep.type === 'section' && stepToMove) {
      return {
        ...state,
        steps: [
          ...finalSteps.slice(0, sectionIndex),
          {
            ...sectionStep,
            steps: concat([stepToMove], reject(sectionStep.steps, s => s.id === action.stepId))
          },
          ...finalSteps.slice(sectionIndex + 1)

        ]
      }
    }
  }

  return state
}

export const hasSections = (steps: Array<Step>) => {
  return steps.some(function(item) {
    return item.type == 'section'
  })
}

function changeStep<T: Step>(state, stepId, func: (step: Object) => T): Object {
  // First try to find the step in 'steps'
  let inSteps = findAndUpdateStep(state.steps, stepId, state, func, 'steps')

  if (inSteps) return inSteps

  // If we couldn't find it there, it must be in 'quotaCompletedSteps'
  let steps = state.quotaCompletedSteps
  if (steps) {
    let inQuotaCompleted = findAndUpdateStep(steps, stepId, state, func, 'quotaCompletedSteps')
    if (inQuotaCompleted) return inQuotaCompleted
  }

  throw new Error(`Bug: couldn't find step ${stepId}`)
}

function findAndUpdateStep<T: Step>(steps, stepId, state, func: (step: Step) => T, key) {
  if (hasSections(steps)) {
    return findAndUpdateStepInSection(steps, stepId, state, func, key)
  } else {
    return findAndUpdateRegularStep(steps, stepId, state, func, key)
  }
}

function findAndUpdateStepInSection<T: Step>(items, stepId, state, func: (step: Object) => T, key) {
  let indexes = findStepAndSectionIndex(stepId, items)

  let sectionIndex = indexes[0]
  let stepIndex = indexes[1]

  if (sectionIndex != -1 && sectionIndex != null) {
    if (stepIndex != null) {
      const sectionStep = items[sectionIndex]
      const steps = sectionStep.steps

      return {
        ...state,
        [key]: [
          ...items.slice(0, sectionIndex),
          {
            ...sectionStep,
            steps: [
              ...steps.slice(0, stepIndex),
              func(steps[stepIndex]),
              ...steps.slice(stepIndex + 1)
            ].filter(x => !x.delete)
          },
          ...items.slice(sectionIndex + 1)
        ]
      }
    } else {
      return updateRegularStep(state, items, sectionIndex, func, key)
    }
  }
}

function findStepAndSectionIndex(stepId, items) {
  let sectionIndex = null
  let stepIndex = null

  items.forEach((item, index) => {
    if (item.type === 'section') {
      let indexInSection = findIndex(item.steps, s => s.id == stepId)
      if (indexInSection != -1) {
        sectionIndex = index
        stepIndex = indexInSection
      }
    } else {
      if (item.id == stepId) {
        sectionIndex = index
        stepIndex = null
      }
    }
  })

  return [sectionIndex, stepIndex]
}

function findAndUpdateRegularStep<T: Step>(steps, stepId, state, func: Object => T, key) {
  let stepIndex = findIndex(steps, s => s.id == stepId)

  if (stepIndex != -1 && stepIndex != null) {
    return updateRegularStep(state, steps, stepIndex, func, key)
  }
}

function updateRegularStep<T: Step>(state, steps, stepIndex, func: Object => T, key) {
  return {
    ...state,
    [key]: [
      ...steps.slice(0, stepIndex),
      func(steps[stepIndex]),
      ...steps.slice(stepIndex + 1)
    ].filter(x => !x.delete)
  }
}

type ActionChangeStepSmsPrompt = {
  stepId: string,
  newPrompt: string
};

const changeStepSmsPrompt = (state, action: ActionChangeStepSmsPrompt) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, state.activeLanguage, prompt => ({
      ...prompt,
      sms: action.newPrompt.trim()
    }))
  })
}

const changeStepMobileWebPrompt = (state, action: ActionChangeStepSmsPrompt) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, state.activeLanguage, prompt => ({
      ...prompt,
      mobileweb: action.newPrompt.trim()
    }))
  })
}

const autocompleteStepSmsPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => {
    // First change default language
    step = setStepPrompt(step, state.defaultLanguage, prompt => ({
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

const autocompleteStepIvrPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => {
    // First change default language
    step = setStepPrompt(step, state.defaultLanguage, prompt => ({
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

const changeStepIvrPrompt = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, state.activeLanguage, prompt => ({
      ...prompt,
      ivr: {
        ...prompt.ivr,
        text: action.newPrompt.text.trim(),
        audioSource: action.newPrompt.audioSource
      }
    }))
  })
}

const changeStepIvrAudioId = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return setStepPrompt(step, state.activeLanguage, prompt => ({
      ...prompt,
      ivr: {
        ...prompt.ivr,
        audioId: action.newId,
        audioSource: action.audioSource
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
        let prompt = {
          'en': newStepPrompt()
        }
        let store = ''
        if (step.type !== 'flag' && step.type !== 'explanation') {
          store = step.store
          prompt = step.prompt
        }
        return {
          id: step.id,
          title: step.title,
          store: store,
          type: action.stepType,
          prompt: prompt,
          choices: []
        }
      })
    case 'numeric':
      return changeStep(state, action.stepId, step => {
        let prompt = {
          'en': newStepPrompt()
        }
        let store = ''
        if (step.type !== 'flag' && step.type !== 'explanation') {
          store = step.store
          prompt = step.prompt
        }
        return {
          id: step.id,
          title: step.title,
          store: store,
          type: action.stepType,
          prompt: prompt,
          minValue: null,
          maxValue: null,
          rangesDelimiters: null,
          ranges: [{from: null, to: null, skipLogic: null}],
          refusal: newRefusal()
        }
      })
    case 'explanation':
      return changeStep(state, action.stepId, step => {
        let prompt = {
          'en': newStepPrompt()
        }
        if (step.type !== 'flag' && step.type !== 'explanation') {
          prompt = step.prompt
        }
        return {
          id: step.id,
          type: action.stepType,
          title: step.title,
          prompt: prompt,
          skipLogic: null
        }
      })
    case 'flag':
      return changeStep(state, action.stepId, step => {
        return {
          id: step.id,
          type: action.stepType,
          disposition: 'interim partial',
          title: step.title,
          skipLogic: null
        }
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

const addSection = (state, action) => {
  let section = newSection()
  if (hasSections(state.steps)) {
    return {
      ...state,
      steps: [
        ...state.steps,
        {...section,
          steps: [
            newMultipleChoiceStep()
          ]
        }
      ]
    }
  } else {
    if (state.steps[0] && state.steps[0].type === 'language-selection') {
      return {
        ...state,
        steps: [
          state.steps[0],
          {...section,
            steps: [
              ...state.steps.slice(1)
            ]
          }
        ]
      }
    } else {
      return {
        ...state,
        steps: [
          {...section,
            steps: [
              ...state.steps
            ]
          }
        ]
      }
    }
  }
}

const toggleRandomizeForSection = (state, action) => {
  const items = state.steps
  let sectionIndex = findIndex(items, s => s.id == action.sectionId)

  const sectionStep = items[sectionIndex]

  if (sectionStep !== null && sectionStep.type === 'section') {
    return {
      ...state,
      steps: [
        ...items.slice(0, sectionIndex),
        {
          ...sectionStep,
          randomize: !sectionStep.randomize
        },
        ...items.slice(sectionIndex + 1)
      ]
    }
  } else {
    return state
  }
}

const addStep = (state, action) => {
  return {
    ...state,
    steps: [
      ...state.steps,
      newMultipleChoiceStep()
    ]
  }
}

const addStepToSection = (state, action) => {
  const step = newMultipleChoiceStep()
  const items = state.steps
  let sectionIndex = findIndex(items, s => s.id == action.sectionId)

  const sectionStep = items[sectionIndex]

  if (sectionStep !== null && sectionStep.type === 'section') {
    return {
      ...state,
      steps: [
        ...items.slice(0, sectionIndex),
        {
          ...sectionStep,
          steps: [
            ...sectionStep.steps,
            step
          ]
        },
        ...items.slice(sectionIndex + 1)
      ]
    }
  } else {
    return state
  }
}

const addQuotaCompletedStep = (state, action) => {
  if (!state.quotaCompletedSteps) {
    throw new Error('Bug: expected state.quotaCompletedStepsComponent to be present')
  }

  return {
    ...state,
    quotaCompletedSteps: [
      ...state.quotaCompletedSteps,
      newMultipleChoiceStep()
    ]
  }
}

export const newLanguageSelectionStep = (first: string, second: string): LanguageSelectionStep => {
  return {
    id: uuidv4(),
    type: 'language-selection',
    title: 'Language selection',
    store: 'language',
    prompt: newStepPrompt(),
    languageChoices: [first, second]
  }
}

export const newMultipleChoiceStep = () => {
  return {
    id: uuidv4(),
    type: 'multiple-choice',
    title: '',
    store: '',
    prompt: {
      'en': newStepPrompt()
    },
    choices: []
  }
}

export const newSection = (): SectionStep => {
  return {
    id: uuidv4(),
    title: '',
    randomize: false,
    type: 'section',
    steps: []
  }
}

const setActiveMode = (state, action) => {
  if (state.activeMode != action.mode) {
    return {
      ...state,
      activeMode: action.mode
    }
  } else {
    return state
  }
}

const addMode = (state, action) => {
  const modes = [...state.modes, ...[action.mode]]
  const activeMode = state.modes.length == 0 ? action.mode : state.activeMode
  return {
    ...state,
    modes,
    activeMode
  }
}

const removeMode = (state, action) => {
  const modes = state.modes.filter(mode => mode != action.mode)
  const activeMode = state.activeMode == action.mode ? defaultActiveMode(modes) : state.activeMode
  return {
    ...state,
    modes,
    activeMode
  }
}

const toggleQuotaCompletedSteps = (state, action) => {
  if (state.quotaCompletedSteps) {
    return {
      ...state,
      quotaCompletedSteps: null
    }
  } else {
    return {
      ...state,
      quotaCompletedSteps: [newExplanationStep()]
    }
  }
}

export const newExplanationStep = () => ({
  id: uuidv4(),
  type: 'explanation',
  title: '',
  store: '',
  prompt: {
    'en': newStepPrompt()
  },
  skipLogic: null
})

type ActionChangeName = {
  newName: string
};

const changeName = (state: Questionnaire, action: ActionChangeName): Questionnaire => {
  return {
    ...state,
    name: action.newName.trim()
  }
}

const changeDescription = (state, action) => {
  return {
    ...state,
    description: action.newDescription.trim()
  }
}

const addLanguage = (state, action) => {
  if (state.languages.indexOf(action.language) == -1) {
    let steps
    if (state.languages.length == 1) {
      steps = addLanguageSelectionStep(state, action)
    } else {
      steps = addOptionToLanguageSelectionStep(state, action.language).steps
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
    let newSteps = removeOptionFromLanguageSelectionStep(state, action.language).steps

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
      choices.splice(action.index - 1, 0, action.language)
    }

    return changeStep(state, state.steps[0].id, (step) => ({
      ...step,
      languageChoices: choices
    }))
  } else {
    return state
  }
}

type LocalizedSettingKey = 'errorMessage' | 'thankYouMessage';
type MsgAction<T> = {msgKey: LocalizedSettingKey, msg: T};

const updateLocalizedPrompt = (localizedPrompt: ?LocalizedPrompt, lang: string, update: Prompt => Prompt): LocalizedPrompt => {
  let newLocalizedPrompt: LocalizedPrompt = {...localizedPrompt}
  // HACK: we use this syntax because otherwise Flow would not type check this assignment
  newLocalizedPrompt[lang] = update(newLocalizedPrompt[lang])
  return newLocalizedPrompt
}

const setQuestionnaireAudioMsg = (state: Questionnaire, key: LocalizedSettingKey, msg: AudioPrompt): Questionnaire => {
  const audioPrompt = {
    ...msg,
    text: msg.text.trim()
  }

  return {...state,
    settings: {...state.settings,
      [key]: updateLocalizedPrompt(state.settings[key], state.activeLanguage, prompt => ({...prompt,
        ivr: audioPrompt
      }))
    }
  }
}

const setQuestionnaireTextMsg = (state: Questionnaire, key: LocalizedSettingKey, msg: string, mode: 'sms' | 'mobileweb'): Questionnaire => {
  const textPrompt = msg.trim()

  return {...state,
    settings: {...state.settings,
      [key]: updateLocalizedPrompt(state.settings[key], state.activeLanguage, prompt => ({...prompt,
        [mode]: textPrompt
      }))
    }
  }
}

const setIvrQuestionnaireMsg = (state: Questionnaire, action: MsgAction<AudioPrompt>): Questionnaire => {
  return setQuestionnaireAudioMsg(state, action.msgKey, action.msg)
}

const setSmsQuestionnaireMsg = (state: Questionnaire, action: MsgAction<string>) => {
  return setQuestionnaireTextMsg(state, action.msgKey, action.msg, 'sms')
}

const setMobileWebQuestionnaireMsg = (state: Questionnaire, action: MsgAction<string>) => {
  return setQuestionnaireTextMsg(state, action.msgKey, action.msg, 'mobileweb')
}

const autocompleteSmsQuestionnaireMsg = (state, action) => {
  let lang = state.defaultLanguage
  let msgKey = action.msgKey
  let item = action.item
  let msg = Object.assign({}, state.settings[msgKey])

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
    settings: {
      ...state.settings,
      [msgKey]: msg
    }
  }
}

const autocompleteIvrQuestionnaireMsg = (state, action) => {
  let lang = state.defaultLanguage
  let msgKey = action.msgKey
  let item = action.item
  let msg = Object.assign({}, state.settings[msgKey])

  // First default language
  let langPrompt = msg[lang] || {}
  let ivr = langPrompt.ivr || newIvrPrompt()
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
    settings: {
      ...state.settings,
      [msgKey]: msg
    }
  }
}

const setMobileWebSettingText = (state, action) => {
  return {
    ...state,
    settings: {
      ...state.settings,
      [action.key]: action.text
    }
  }
}

const setMobileWebSurveyIsOverMessage = (state, action) => {
  return {
    ...state,
    settings: {
      ...state.settings,
      mobileWebSurveyIsOverMessage: action.text
    }
  }
}

const setDisplayedTitle = (state, action) => {
  const lang = state.activeLanguage
  const title = state.settings.title || {}
  return {
    ...state,
    settings: {
      ...state.settings,
      title: {
        ...title,
        [lang]: action.msg
      }
    }
  }
}

const setSurveyAlreadyTakenMessage = (state, action) => {
  const lang = state.activeLanguage
  const surveyAlreadyTakenMessage = state.settings.surveyAlreadyTakenMessage || {}
  return {
    ...state,
    settings: {
      ...state.settings,
      surveyAlreadyTakenMessage: {
        ...surveyAlreadyTakenMessage,
        [lang]: action.msg
      }
    }
  }
}

const addOptionToLanguageSelectionStep = (state, language) => {
  return changeStep(state, state.steps[0].id, (step) => ({
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

    return changeStep(state, languageSelectionStep.id, (step) => ({
      ...step,
      languageChoices: newLanguages
    }))
  } else {
    return state
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

export const stepStoreValues = (questionnaire: Questionnaire) => {
  const multipleChoiceSteps = reject(questionnaire.steps, (step) =>
    step.type == 'language-selection'
  )

  const reduceStep = (options, step) => {
    options[step.store] = {
      type: step.type,
      values: map(step.choices, (choice) =>
        choice.value
      )
    }
    return options
  }

  return reduce(multipleChoiceSteps, (options, step) => {
    if (step.type === 'section') {
      return reduce(step.steps, reduceStep, options)
    } else {
      return reduceStep(options, step)
    }
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

  csvStepsTranslations(questionnaire.steps, context, defaultLang)

  if (questionnaire.quotaCompletedSteps) {
    csvStepsTranslations(questionnaire.quotaCompletedSteps, context, defaultLang)
  }

  if (questionnaire.settings.errorMessage) {
    addMessageToCsvForTranslation(questionnaire.settings.errorMessage, defaultLang, context)
  }

  if (questionnaire.settings.thankYouMessage) {
    addMessageToCsvForTranslation(questionnaire.settings.thankYouMessage, defaultLang, context)
  }

  const title = questionnaire.settings.title
  if (title) {
    const defaultTitle = title[defaultLang]
    if (defaultTitle && defaultTitle.trim().length != 0) {
      addToCsvForTranslation(defaultTitle, context, lang => title[lang] || '')
    }
  }

  const surveyAlreadyTakenMessage = questionnaire.settings.surveyAlreadyTakenMessage
  if (surveyAlreadyTakenMessage) {
    const defaultMessage = surveyAlreadyTakenMessage[defaultLang]
    if (defaultMessage && defaultMessage.trim().length != 0) {
      addToCsvForTranslation(defaultMessage, context, lang =>
        surveyAlreadyTakenMessage[lang] || ''
      )
    }
  }

  return rows
}

const csvStepsTranslations = (steps, context, defaultLang) => {
  steps.forEach(step => {
    if (step.type === 'section') {
      step.steps.forEach(sectionStep => {
        stepTranslations(sectionStep, context, defaultLang)
      })
    } else {
      stepTranslations(step, context, defaultLang)
    }
  })
}

const stepTranslations = (step, context, defaultLang) => {
  if (step.type !== 'language-selection') {
    // Sms Prompt
    let defaultSms = getStepPromptSms(step, defaultLang)
    addToCsvForTranslation(defaultSms, context, lang => getStepPromptSms(step, lang))

    // Ivr Prompt
    let defaultIvr = getStepPromptIvrText(step, defaultLang)
    addToCsvForTranslation(defaultIvr, context, lang => getStepPromptIvrText(step, lang))

    // Mobile Web Prompt
    let defaultMobileWeb = getStepPromptMobileWeb(step, defaultLang)
    addToCsvForTranslation(defaultMobileWeb, context, lang => getStepPromptMobileWeb(step, lang))

    // Sms Prompt. Note IVR responses shouldn't be translated because it is expected to be a digit.
    if (step.type === 'multiple-choice') {
      step.choices.forEach(choice => {
        // Response sms
        const defaultResponseSms = getChoiceResponseSmsJoined(choice, defaultLang)
        addToCsvForTranslation(defaultResponseSms, context, lang =>
          getChoiceResponseSmsJoined(choice, lang)
        )

        // Response mobile web
        const defaultResponseMobileWeb = getChoiceResponseMobileWebJoined(choice, defaultLang)
        addToCsvForTranslation(defaultResponseMobileWeb, context, lang =>
          getChoiceResponseMobileWebJoined(choice, lang)
        )
      })
    }
  }
}

const addMessageToCsvForTranslation = (m, defaultLang, context) => {
  let defaultSmsCompletedMsg = getPromptSms(m, defaultLang)
  addToCsvForTranslation(defaultSmsCompletedMsg, context, lang => getPromptSms(m, lang))

  let defaultIvrCompletedMsg = getPromptIvrText(m, defaultLang)
  addToCsvForTranslation(defaultIvrCompletedMsg, context, lang => getPromptIvrText(m, lang))

  let defaultMobileWebCompletedMsg = getPromptMobileWeb(m, defaultLang)
  addToCsvForTranslation(defaultMobileWebCompletedMsg, context, lang => getPromptMobileWeb(m, lang))
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
    let minValue: ?number = safeParseInt(action.minValue)
    let maxValue: ?number = safeParseInt(action.maxValue)
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

const safeParseInt = (obj) => {
  if (typeof (obj) == 'string') {
    if (obj.trim().length == 0) {
      return null
    } else {
      return parseInt(obj)
    }
  } else if (obj != null) {
    return parseInt(obj)
  } else {
    return null
  }
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

const toggleAcceptsAlphabeticalAnswers = (state, action) => {
  return changeStep(state, action.stepId, step => {
    const alphabeticalAnswers = step.alphabeticalAnswers || false
    return {
      ...step,
      alphabeticalAnswers: !alphabeticalAnswers
    }
  })
}

const changeRefusal = (state, action) => {
  return changeStep(state, action.stepId, step => {
    return {
      ...step,
      refusal: {
        ...step.refusal,
        responses: {
          ivr: splitValues(action.ivrValues),
          sms: {
            ...step.refusal.responses.sms,
            [state.activeLanguage]: splitValues(action.smsValues)
          },
          mobileweb: {
            ...step.refusal.responses.mobileweb,
            [state.activeLanguage]: action.mobilewebValues
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

  let newState = {
    ...state,
    settings: {...state.settings},
    steps: translateSteps(state.steps, defaultLanguage, lookup)
  }

  if (state.quotaCompletedSteps) {
    newState = {
      ...newState,
      quotaCompletedSteps: translateSteps(state.quotaCompletedSteps, defaultLanguage, lookup)
    }
  }

  if (state.settings.errorMessage) {
    newState.settings.errorMessage = translatePrompt(state.settings.errorMessage, defaultLanguage, lookup)
  }

  if (state.settings.thankYouMessage) {
    newState.settings.thankYouMessage = translatePrompt(state.settings.thankYouMessage, defaultLanguage, lookup)
  }

  if (state.settings.title) {
    newState.settings.title = translateLanguage(state.settings.title, defaultLanguage, lookup)
  }

  if (state.settings.title) {
    newState.settings.surveyAlreadyTakenMessage = translateLanguage(state.settings.surveyAlreadyTakenMessage, defaultLanguage, lookup)
  }

  return newState
}

const translateSteps = (steps, defaultLanguage, lookup) => {
  return steps.map(step => {
    if (step.type === 'section') {
      return {
        ...step,
        steps: step.steps.map(sectionStep => translateStep(sectionStep, defaultLanguage, lookup))
      }
    } else {
      return translateStep(step, defaultLanguage, lookup)
    }
  })
}

const translateStep = (step, defaultLanguage, lookup): Step => {
  let newStep = {...step}
  if (step.type !== 'language-selection' && step.type !== 'flag' && step.type !== 'section') {
    newStep.prompt = translatePrompt(step.prompt, defaultLanguage, lookup)
    if (step.type === 'multiple-choice') {
      newStep = {...newStep, choices: translateChoices(step.choices, defaultLanguage, lookup)}
    }
  }
  return ((newStep: any): Step)
}

const translatePrompt = (prompt, defaultLanguage, lookup): LocalizedPrompt => {
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

  let mobileweb = defaultLanguagePrompt.mobileweb
  if (mobileweb && (translations = lookup[mobileweb])) {
    addTranslations(newPrompt, translations, 'mobileweb')
  }

  return newPrompt
}

const translateLanguage = (obj, defaultLanguage, lookup) => {
  if (!obj) return obj
  let defaultLanguageMessage = obj[defaultLanguage]
  if (!defaultLanguageMessage) return obj

  let translations = lookup[defaultLanguageMessage.trim()]
  if (!translations) return obj

  let newObj = {...obj}
  for (let lang in translations) {
    const text = translations[lang]
    newObj[lang] = (text || '').trim()
  }

  return newObj
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

  let newChoice = {
    ...choice,
    responses: {...choice.responses}
  }

  if (responses.sms && responses.sms[defaultLanguage]) {
    const defLangSms = getChoiceResponseSmsJoined(choice, defaultLanguage)
    newChoice.responses.sms = processTranslationsArray(defLangSms, newChoice.responses.sms || {}, lookup)
  }

  if (responses.mobileweb && responses.mobileweb[defaultLanguage]) {
    const defLangMobileWeb = getChoiceResponseMobileWebJoined(choice, defaultLanguage)
    newChoice.responses.mobileweb = processTranslationsString(defLangMobileWeb, newChoice.responses.mobileweb || {}, lookup)
  }

  return newChoice
}

const processTranslationsArray = (value, obj, lookup, split = true) => {
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

const processTranslationsString = (value, obj, lookup) => {
  let translations

  if (value && (translations = lookup[value])) {
    for (let lang in translations) {
      obj = {
        ...obj,
        [lang]: translations[lang]
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

const setPrimaryColor = (state, action) => {
  return {
    ...state,
    settings: {
      ...state.settings,
      mobileWebColorStyle: {
        ...state.settings.mobileWebColorStyle,
        primaryColor: action.color
      }
    }
  }
}

const setSecondaryColor = (state, action) => {
  return {
    ...state,
    settings: {
      ...state.settings,
      mobileWebColorStyle: {
        ...state.settings.mobileWebColorStyle,
        secondaryColor: action.color
      }
    }
  }
}

const setDirty = (state) => ({...state})
