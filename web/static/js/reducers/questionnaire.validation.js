// @flow
import * as characterCounter from '../characterCounter'
import { getStepPrompt, splitSmsText, newStepPrompt, newIvrPrompt } from '../step'
import { hasSections } from './questionnaire'

const k = (...args: any) => args

type ValidationContext = {
  sms: boolean,
  ivr: boolean,
  mobileweb: boolean,
  activeLanguage: string,
  languages: string[],
  errors: ValidationError[],
  hasSections: boolean
};

export const validate = (state: DataStore<Questionnaire>) => {
  const data = state.data
  if (!data) return
  state.errors = []

  const context = {
    sms: data.modes.indexOf('sms') != -1,
    ivr: data.modes.indexOf('ivr') != -1,
    mobileweb: data.modes.indexOf('mobileweb') != -1,
    activeLanguage: data.activeLanguage,
    languages: data.languages,
    errors: state.errors,
    hasSections: hasSections(data.steps)
  }

  validateSteps(data.steps, context, 'steps')

  if (data.quotaCompletedSteps) {
    validateSteps(data.quotaCompletedSteps, context, 'quotaCompletedSteps')
  }

  validateDuplicateStepStore(data.steps, data.quotaCompletedSteps, context)

  validateMessage('errorMessage', data.settings.errorMessage, context)
  validateThankYouMessage(data.settings.thankYouMessage, context)

  validateTitle(data, context)
  validateMobileWebSmsMessage(data, context)
  validateMobileWebSurveyIsOverMessage(data, context)
  validateSurveyAlreadyTakenMessage(data, context)
  validateMobileWebColorStyle(data, context)

  state.errorsByPath = errorsByPath(state.errors)
  state.errorsByLang = errorsByLang(state.errors)
}

const errorsByPath = (errors) => {
  const errorsByPath = {}
  for (const error of errors) {
    errorsByPath[error.path] = errorsByPath[error.path] || []
    errorsByPath[error.path].push(error.message)
  }
  return errorsByPath
}

const errorsByLang = (errors) => {
  const errorsByLang = {}
  for (const error of errors) {
    if (error.lang) {
      errorsByLang[error.lang] = true
    }
  }
  return errorsByLang
}

const validateSteps = (steps, context: ValidationContext, path: string) => {
  for (let i = 0; i < steps.length; i++) {
    validateStep(steps[i], i, context, steps, `${path}[${i}]`)
  }
}

const validateStep = (step: Step, stepIndex: number, context: ValidationContext, steps, path: string) => {
  switch (step.type) {
    case 'language-selection':
      return validateLanguageSelectionStep(step, stepIndex, context, steps, path)
    case 'flag':
      return validateFlagStep(step, stepIndex, context, steps, path)
    case 'multiple-choice':
      return validateMultipleChoiceStep(step, stepIndex, context, steps, path)
    case 'numeric':
      return validateNumericStep(step, stepIndex, context, steps, path)
    case 'explanation':
      return validateExplanationStep(step, stepIndex, context, steps, path)
    case 'section':
      return validateSteps(step.steps, context, `${path}.steps`)
    default:
  }
}

const validateLanguageSelectionStep = (step, stepIndex, context, steps, path) => {
  validatePrompt(step.prompt, context, null, `${path}.prompt`)
}

const validateFlagStep = (step, stepIndex, context, steps, path) => {
  validateStepSkipLogic(step, stepIndex, steps, context, path)
}

const validateMultipleChoiceStep = (step, stepIndex, context, steps, path) => {
  validatePrompts(step, context, path)
  validateChoices(step.choices, stepIndex, context, steps, path)
}

const validateNumericStep = (step, stepIndex, context, steps, path) => {
  validatePrompts(step, context, path)
  validateRangeDelimiters(step, context, path)
  validateRanges(step.ranges, stepIndex, context, steps, path)
  validateRefusal(step, stepIndex, context, steps, path)
}

const validateRefusal = (step: NumericStep, stepIndex, context, steps, path) => {
  if (step.refusal && step.refusal.enabled) {
    validateChoiceOrRefusal(step.refusal, context, stepIndex, stepIndex, steps, `${path}.refusal[refusal]`)
  }
}

const validateExplanationStep = (step, stepIndex, context, steps, path) => {
  validatePrompts(step, context, path)
  validateStepSkipLogic(step, stepIndex, steps, context, path)
}

const validatePrompts = (step, context, path) => {
  path = `${path}.prompt`

  context.languages.forEach(lang => {
    const langPath = `${path}['${lang}']`
    const prompt = getStepPrompt(step, lang)
    validatePrompt(prompt, context, lang, langPath)
  })
}

const validatePrompt = (prompt: ?Prompt, context, lang, langPath) => {
  prompt = prompt || newStepPrompt()

  if (context.sms) {
    validateSmsLangPrompt(prompt, context, lang, langPath)
  }

  if (context.ivr) {
    validateIvrLangPrompt(prompt, context, lang, langPath)
  }

  if (context.mobileweb) {
    validateMobileWebLangPrompt(prompt, context, lang, langPath)
  }
}

const validateSmsLangPrompt = (prompt: Prompt, context: ValidationContext, lang: ?string, path: string) => {
  if (isBlank(prompt.sms)) {
    addError(context, `${path}.sms`, k('SMS prompt must not be blank'), lang, 'sms')
    return
  }

  const parts = splitSmsText(prompt.sms || '')
  if (parts.some(p => characterCounter.limitExceeded(p))) {
    addError(context, `${path}.sms`, 'limit exceeded', lang, 'sms')
  }
}

const validateIvrLangPrompt = (prompt: Prompt, context: ValidationContext, lang: ?string, path: string) => {
  let ivr = prompt.ivr || newIvrPrompt()
  if (isBlank(ivr.text)) {
    addError(context, `${path}.ivr.text`, k('Voice prompt must not be blank'), lang, 'ivr')
  }
  if (ivr.audioSource == 'upload' && !ivr.audioId) {
    addError(context, `${path}.ivr.audioId`, k('An audio file must be uploaded'), lang, 'ivr')
  }
}

const validateMobileWebLangPrompt = (prompt: Prompt, context: ValidationContext, lang: ?string, path: string) => {
  if (isBlank(prompt.mobileweb)) {
    addError(context, `${path}.mobileweb`, k('Mobile web prompt must not be blank'), lang, 'mobileweb')
  }
}

const skipLogicError = (skipLogic, stepIndex, steps, context) => {
  if (!skipLogic || skipLogic == 'end') {
    return null
  }
  if (skipLogic == 'end_section') {
    if (!context.hasSections) {
      return k('Cannot jump to end of section if there is no sections')
    } else {
      return null
    }
  }
  let currentValueIsValid = false
  steps.slice(stepIndex + 1).map(s => {
    if (skipLogic === s.id) {
      currentValueIsValid = true
    }
  })
  if (!currentValueIsValid) {
    return k('Cannot jump to a previous step or step outside section')
  } else {
    return null
  }
}

const validateStepSkipLogic = (step, stepIndex, steps, context, path) => {
  const error = skipLogicError(step.skipLogic, stepIndex, steps, context)
  if (error) {
    addError(context, `${path}.skipLogic`, error)
  }
}

const validateChoiceSkipLogic = (choice, stepIndex, choiceIndex, steps, context, path) => {
  const error = skipLogicError(choice.skipLogic, stepIndex, steps, context)
  if (error) {
    addError(context, `${path}.skipLogic`, error)
  }
}

const validateRangeSkipLogic = (range, stepIndex, steps, context, path) => {
  const error = skipLogicError(range.skipLogic, stepIndex, steps, context)
  if (error) {
    // TODO: missing range info in path
    addError(context, `${path}.skipLogic`, error)
  }
}

const validateRangeDelimiters = (step, context, path) => {
  if (step.minValue != null && step.maxValue != null && step.minValue >= step.maxValue) {
    addError(context, `${path}.maxValue`, k('Max value must be greater than the min value'))
  }

  let delimiters = step.rangesDelimiters
  if (!delimiters) return

  delimiters = delimiters.split(',').map(x => x.trim())

  let previous = null

  for (const delimiter of delimiters) {
    const int = parseInt(delimiter)

    if (isNaN(int)) {
      addError(context, `${path}.rangesDelimiters`, k('Delimiter "{{delimiter}}" must be a number', {delimiter}))
    }

    if (previous == null && step.minValue != null && step.minValue > int) {
      addError(context, `${path}.minValue`, k('Min value must be less than or equal to the first delimiter ({{first}})', {first: int}))
    }

    if (previous != null && int <= previous) {
      addError(context, `${path}.rangesDelimiters`, k('Delimiter {{delimiter}} must be greater than the previous one ({{previous}})', {delimiter, previous}))
    }

    if (!isNaN(int)) {
      previous = int
    }
  }

  if (previous != null && step.maxValue != null && step.maxValue < previous) {
    addError(context, `${path}.maxValue`, k('Max value must be greater than or equal to the last delimiter ({{last}})', {last: previous}))
  }
}

const validateRanges = (ranges, stepIndex, context, steps, path) => {
  for (const range of ranges) {
    validateRangeSkipLogic(range, stepIndex, steps, context, path)
  }
}

const validateChoices = (choices: Choice[], stepIndex: number, context: ValidationContext, steps, path) => {
  path = `${path}.choices`

  if (choices.length < 2) {
    addError(context, path, k('You should define at least two response options'))
  }

  for (let i = 0; i < choices.length; i++) {
    validateChoice(choices[i], context, stepIndex, i, steps, `${path}[${i}]`)
  }

  const values = []
  let sms = {}
  let ivr = []
  let mobileweb = {}

  for (let i = 0; i < choices.length; i++) {
    const choicePath = `${path}[${i}]`

    let choice = choices[i]
    if (values.includes(choice.value)) {
      addError(context, `${choicePath}.value`, k('Value already used in a previous response'))
    }

    if (context.sms) {
      context.languages.forEach(lang => validateSmsResponseDuplicates(choice, context, stepIndex, i, lang, sms, `${choicePath}['${lang}']`))
    }

    if (context.ivr) {
      if (choice.responses.ivr) {
        for (let choiceIvr of choice.responses.ivr) {
          if (ivr.includes(choiceIvr)) {
            addError(context, `${choicePath}.ivr`, k('Value "{{value}}" already used in a previous response', {value: choiceIvr}), null, 'ivr')
          }
        }
        ivr.push(...choice.responses.ivr)
      }
    }

    if (context.mobileweb) {
      context.languages.forEach(lang => validateMobileWebResponseDuplicates(choice, context, stepIndex, i, lang, mobileweb, `${choicePath}['${lang}']`))
    }

    values.push(choice.value)
  }
}

const validateSmsResponseDuplicates = (choice: Choice, context: ValidationContext, stepIndex: number, choiceIndex: number, lang: string, otherSms, path) => {
  if (choice.responses.sms && choice.responses.sms[lang]) {
    for (let choiceSms of choice.responses.sms[lang]) {
      if (otherSms[lang] && otherSms[lang].includes(choiceSms)) {
        addError(context, `${path}.sms`, k('Value "{{value}}" already used in a previous response', {value: choiceSms}), lang, 'sms')
      }
    }

    if (!otherSms[lang]) {
      otherSms[lang] = []
    }

    otherSms[lang].push(...choice.responses.sms[lang])
  }
}

const validateMobileWebResponseDuplicates = (choice: Choice, context: ValidationContext, stepIndex: number, choiceIndex: number, lang: string, otherMobileWeb, path) => {
  if (choice.responses.mobileweb && choice.responses.mobileweb[lang]) {
    let mobilewebSms = choice.responses.mobileweb[lang]
    if (otherMobileWeb[lang] && otherMobileWeb[lang].includes(mobilewebSms)) {
      addError(context, `${path}.mobileweb`, k('Value "{{value}}" already used in a previous response', {value: mobilewebSms}), lang, 'mobileweb')
    }

    if (!otherMobileWeb[lang]) {
      otherMobileWeb[lang] = []
    }

    otherMobileWeb[lang].push(choice.responses.mobileweb[lang])
  }
}

const validateChoiceSmsResponse = (choice, context, stepIndex: number, choiceIndex: number, lang: string, path: string) => {
  let sms = choice.responses.sms
  if (!sms) return

  sms = sms[lang]
  if (!sms) return

  path = `${path}.sms`

  if (sms.length == 0) {
    addError(context, path, k('"SMS" must not be blank'), lang, 'sms')
  }

  if (sms.some(x => x.toLowerCase() == 'stop')) {
    addError(context, path, k('"SMS" cannot be "STOP"'), lang, 'sms')
  }
}

const validateChoiceMobileWebResponse = (choice, context, stepIndex: number, choiceIndex: number, lang: string, path: string) => {
  if (!choice.responses.mobileweb || isBlank(choice.responses.mobileweb[lang])) {
    addError(context, `${path}.mobileweb`, k('"Mobile web" must not be blank'), lang, 'mobileweb')
  }
}

const validateChoiceIvrResponse = (choice, context, stepIndex: number, choiceIndex: number, path: string) => {
  path = `${path}.ivr`

  if (choice.responses.ivr &&
      choice.responses.ivr.length == 0) {
    addError(context, path, k('"Phone call" must not be blank'), null, 'ivr')
  }

  if (choice.responses.ivr &&
      choice.responses.ivr.some(value => !value.match('^[0-9#*]*$'))) {
    addError(context, path, k('"Phone call" must only consist of single digits, "#" or "*"'), null, 'ivr')
  }
}

const validateChoice = (choice: Choice, context: ValidationContext, stepIndex: number, choiceIndex: number, steps, path) => {
  if (isBlank(choice.value)) {
    addError(context, `${path}.value`, k('Response must not be blank'))
  }
  validateChoiceOrRefusal(choice, context, stepIndex, choiceIndex, steps, path)
}

const validateChoiceOrRefusal = (choice: Choice | Refusal, context: ValidationContext, stepIndex: number, choiceIndex: number, steps, path) => {
  context.languages.forEach(lang => {
    const langPath = `${path}['${lang}']`

    if (context.sms) {
      validateChoiceSmsResponse(choice, context, stepIndex, choiceIndex, lang, langPath)
    }

    if (context.mobileweb) {
      validateChoiceMobileWebResponse(choice, context, stepIndex, choiceIndex, lang, langPath)
    }
  })

  if (context.ivr) {
    validateChoiceIvrResponse(choice, context, stepIndex, choiceIndex, path)
  }

  validateChoiceSkipLogic(choice, stepIndex, choiceIndex, steps, context, path)
}

const validateMessage = (msgKey: string, msg: ?LocalizedPrompt, context: ValidationContext) => {
  msg = msg || {}

  const path = `${msgKey}.prompt`

  context.languages.forEach(lang => {
    if (msg) {
      validatePrompt(msg[lang], context, lang, `${path}['${lang}']`)
    }
  })
}

const validateThankYouMessage = (msg: ?LocalizedPrompt, context: ValidationContext) => {
  msg = msg || {}

  const path = 'thankYouMessage.prompt'

  if (context.mobileweb) {
    context.languages.forEach(lang => {
      if (msg && msg[lang]) {
        validateMobileWebLangPrompt(msg[lang], context, lang, `${path}['${lang}']`)
      }
    })
  }
}

const validateTitle = (data, context) => {
  if (!context.mobileweb) return

  context.languages.forEach(lang => {
    const text = (data.settings.title || {})[lang]
    if (isBlank(text)) {
      addError(context, `title['${lang}']`, k('Title must not be blank'), lang, 'mobileweb')
    }
  })
}

const validateMobileWebSmsMessage = (data, context) => {
  if (!context.mobileweb) return

  if (isBlank(data.settings.mobileWebSmsMessage)) {
    addError(context, 'mobileWebSmsMessage', k('Mobile web SMS message must not be blank'), null, 'mobileweb')
    return
  }

  const parts = splitSmsText(data.settings.mobileWebSmsMessage || '')
  const exceeds = parts.some((p, i) => {
    // The last part gets appended the link, which we assume will have
    // at most 20 ASCII chars
    if (i == parts.length - 1) {
      p = `${p}${'a'.repeat(20)}`
    }
    return characterCounter.limitExceeded(p)
  })
  if (exceeds) {
    addError(context, 'mobileWebSmsMessage', 'limit exceeded', null, 'mobileweb')
  }
}

const validateMobileWebColorStyle = (data, context) => {
  if (!context.mobileweb) return
  if (!data.settings.mobileWebColorStyle) return
  const colorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
  const primary = data.settings.mobileWebColorStyle.primaryColor
  const secondary = data.settings.mobileWebColorStyle.secondaryColor
  if (primary) {
    if (!colorRegex.test(primary)) {
      addError(context, 'mobileWebColorStyle.primaryColor', k('Mobile web primary color is invalid '), null, 'mobileweb')
    }
  }
  if (secondary) {
    if (!colorRegex.test(secondary)) {
      addError(context, 'mobileWebColorStyle.secondaryColor', k('Mobile web secondary color is invalid'), null, 'mobileweb')
    }
  }
  return
}

const validateMobileWebSurveyIsOverMessage = (data, context) => {
  if (!context.mobileweb) return

  if (isBlank(data.settings.mobileWebSurveyIsOverMessage)) {
    addError(context, 'mobileWebSurveyIsOverMessage', k('Mobile web "Survey is over" message must not be blank'), null, 'mobileweb')
  }
}

const validateSurveyAlreadyTakenMessage = (data, context) => {
  if (!context.mobileweb) return

  context.languages.forEach(lang => {
    const text = (data.settings.surveyAlreadyTakenMessage || {})[lang]
    if (isBlank(text)) {
      addError(context, `surveyAlreadyTakenMessage['${lang}']`, k('"Survey already taken" message must not be blank'), lang, 'mobileweb')
    }
  })
}

const validateDuplicateStepStore = (steps, quotaCompletedSteps, context) => {
  const stores = {}

  for (let i = 0; i < steps.length; i++) {
    const step = steps[i]
    validateDuplicateStepStore0(step, stores, context, `steps[${i}].store`)
  }

  if (quotaCompletedSteps) {
    for (let i = 0; i < quotaCompletedSteps.length; i++) {
      const step = quotaCompletedSteps[i]
      validateDuplicateStepStore0(step, stores, context, `quotaCompletedSteps[${i}].store`)
    }
  }
}

const validateDuplicateStepStore0 = (step, stores, context, path) => {
  if (step.type !== 'language-selection' &&
    step.type !== 'multiple-choice' &&
    step.type !== 'numeric') {
    return
  }

  let store = step.store
  if (!store) return

  store = store.trim()
  if (store.length == 0) return

  if (stores[store]) {
    addError(context, path, k('Variable already used in a previous step'))
  }

  stores[store] = true
}

const addError = (context, path, message, lang = null, mode = null) => {
  context.errors.push({path, lang, mode, message})
}

const isBlank = (value: ?string) => {
  return !value || value.trim().length == 0
}
