// @flow
import findIndex from 'lodash/findIndex'
import keys from 'lodash/keys'
import some from 'lodash/some'
import reduce from 'lodash/reduce'
import startsWith from 'lodash/startsWith'

/*

Here's a list of current validations on a Questionnaire:

1. For a step, a lang and SMS mode, "blank prompt"
2. For a step, a lang and IVR mode, "blank prompt"

3. For a multiple choice step, "you should define at least 2 choices"

4. For a multiple choice step and a choice, "blank value"
5. For a multiple choice step and a choice, "duplicate choice value"

6. For a multiple choice step and a choice, "IVR response only accepts digits"
7. For a multiple choice step and a choice, "blank IVR response"
8. For a multiple choice step and a choice, "duplicate IVR response"

9. For a multiple choice step, a choice, a lang and SMS, "blank response"
10. For a multiple choice step, a choice, a lang and SMS, "duplicate response"

11. For the error message, a lang and SMS mode, "blank response"
12. For the error message, a lang and IVR mode, "blank response"

13. For the quota completed message, a lang and SMS mode, "blank response"
14. For the quota completed message, a lang and IVR mode, "blank response"

Errors 1, 2, 9-14 depend on language.

*/

type ErrorSubject = {
  stepIndex: ?number,
  choiceIndex: ?number,
  lang: ?string
};

const parseErrorPath = (errorPath: string): ErrorSubject => {
  let errorSubject = {
    stepIndex: null,
    choiceIndex: null,
    lang: null,
    msg: null
  }

  // regex[0] == The whole error path
  // regex[1] == step index
  // regex[2] == lang
  // regex[3] == choice index
  // regex[4] == lang
  // regex[5] == msgKey
  // regex[6] == lang
  const regex = /steps\[(\d+)]\.(?:prompt\[['"](\w+)['"]]|choices\[(\d+)](?:\[['"](\w+)['"]])?|skipLogic)|(errorMsg|quotaCompletedMsg)\.prompt\[['"](\w+)['"]]/g

  const parsedPath = regex.exec(errorPath)

  if (parsedPath) {
    if (parsedPath[1]) {
      errorSubject.stepIndex = parsedPath[1]
    }

    if (parsedPath[2] || parsedPath[4] || parsedPath[6]) {
      errorSubject.lang = parsedPath[2] || parsedPath[4] || parsedPath[6]
    }

    if (parsedPath[3]) {
      errorSubject.choiceIndex = parsedPath[3]
    }

    if (parsedPath[5]) {
      errorSubject.msg = parsedPath[5]
    }
  }

  return errorSubject
}

/**
 * Given a questionnaire with its metadata, returns a dictionary of errors by
 * lang. The errors included for each lang are those specific to the language
 * plus those that do not depend on the language. See the comment at the top of
 * this file for a list of the possible validation errors for a questionnaire.
*/
export const errorsByLang = (quiz: DataStore<Questionnaire>): {[lang: string]: Errors} => {
  const data = quiz.data
  if (!data) return {}
  let initialStruct = reduce(data.languages, (struct, lang) => {
    struct[lang] = {}
    return struct
  }, {})

  return reduce(quiz.errors, (result, currentError, currentErrorPath) => {
    const errorSubject = parseErrorPath(currentErrorPath)

    if (errorSubject.stepIndex || errorSubject.choiceIndex || errorSubject.msg) {
      if (!errorSubject.lang) {
        data.languages.forEach(lang => {
          result[lang][currentErrorPath] = currentError
        })
      } else {
        result[errorSubject.lang][currentErrorPath] = currentError
      }
    }

    return result
  }, initialStruct)
}

export const langHasErrors = (quiz: DataStore<Questionnaire>) => (lang: string): boolean => {
  return keys(quiz.errorsByLang[lang] || {}).length > 0
}

export const hasErrors = (quiz: DataStore<Questionnaire>, step: Step) => {
  const data = quiz.data
  if (!data) return false
  const errorPath = (index) => `steps[${index}]`

  const stepIndex = findIndex(data.steps, s => s.id === step.id)
  return stepIndex >= 0 && some(keys(quiz.errorsByLang[data.activeLanguage]), k => startsWith(k, errorPath(stepIndex)))
}

export const msgHasErrors = (quiz: DataStore<Questionnaire>, msgKey: string) => {
  if (!quiz.data) return false
  return some(keys(quiz.errorsByLang[quiz.data.activeLanguage]), k => startsWith(k, msgPath(msgKey)))
}

export const filterByPathPrefix = (errors: Errors, prefix: string) => {
  return reduce(errors, (stepErrors, currentError, currentErrorPath) => {
    if (startsWith(currentErrorPath, prefix)) {
      stepErrors[currentErrorPath] = currentError
    }

    return stepErrors
  }, {})
}

export const stepsPath = 'steps'
export const stepPath = (stepIndex: number) => `${stepsPath}[${stepIndex}]`
export const stepSkipLogicPath = (stepIndex: number) => `${stepPath(stepIndex)}.skipLogic`

const promptTextPathSuffix = (mode: string, lang: string): string => {
  if (mode === 'ivr') {
    return `prompt['${lang}'].${mode}.text`
  } else {
    return `prompt['${lang}'].${mode}`
  }
}

export const promptTextPath = (stepIndex: number, mode: string, lang: string): string => {
  return `${stepPath(stepIndex)}.${promptTextPathSuffix(mode, lang)}`
}

export const msgPath = (msg: string): string => msg
export const msgPromptTextPath = (msg: string, mode: string, lang: string): string => {
  return `${msgPath(msg)}.${promptTextPathSuffix(mode, lang)}`
}

export const choicesPath = (stepIndex: number) => `${stepPath(stepIndex)}.choices`
export const choicePath = (stepIndex: number, choiceIndex: number) => `${choicesPath(stepIndex)}[${choiceIndex}]`
export const choiceValuePath = (stepIndex: number, choiceIndex: number) => `${choicePath(stepIndex, choiceIndex)}.value`
export const choiceSmsResponsePath = (stepIndex: number, choiceIndex: number, lang: string) => `${choicePath(stepIndex, choiceIndex)}['${lang}'].sms`
export const choiceMobileWebResponsePath = (stepIndex: number, choiceIndex: number, lang: string) => `${choicePath(stepIndex, choiceIndex)}['${lang}'].mobileWeb`
export const choiceIvrResponsePath = (stepIndex: number, choiceIndex: number) => `${choicePath(stepIndex, choiceIndex)}.ivr`
export const choiceSkipLogicPath = (stepIndex: number, choiceIndex: number) => `${choicePath(stepIndex, choiceIndex)}.skipLogic`

export const rangesPath = (stepIndex: number) => `${stepPath(stepIndex)}.ranges`
export const rangePath = (stepIndex: number, rangeFrom: number, rangeTo: number) => `${rangesPath(stepIndex)}[${rangeFrom}-${rangeTo}]`
export const rangeSkipLogicPath = (stepIndex: number, rangeFrom: number, rangeTo: number) => `${rangePath(stepIndex, rangeFrom, rangeTo)}.skipLogic`
