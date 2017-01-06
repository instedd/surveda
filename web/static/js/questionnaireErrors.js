// @flow
import findIndex from 'lodash/findIndex'
import keys from 'lodash/keys'
import some from 'lodash/some'
import reduce from 'lodash/reduce'
import startsWith from 'lodash/startsWith'

/*

Here's a list of current validations on a Questionnaire:

1. For a step, a lang and SMS mode, "blank prompt"
2. For a step, a lang and a TTS IVR prompt, "blank prompt"

3. For a multiple choice step, "you should define at least 2 choices"

4. For a multiple choice step and a choice, "blank value"
5. For a multiple choice step and a choice, "duplicate choice value"

6. For a multiple choice step and a choice, "IVR response only accepts digits"
7. For a multiple choice step and a choice, "blank IVR response"
8. For a multiple choice step and a choice, "duplicate IVR response"

9. For a multiple choice step, a choice, a lang and SMS, "blank response"
10. For a multiple choice step, a choice, a lang and SMS, "duplicate response"

Errors 1, 2, 9 and 10 depend on language.

*/

type ErrorSubject = {
  stepIndex: ?number,
  choiceIndex: ?number,
  lang: ?string
}

const parseErrorPath = (errorPath: string): ErrorSubject => {
  let errorSubject = { stepIndex: null, choiceIndex: null, lang: null }

  // regex[0] == The whole error path
  // regex[1] == step index
  // regex[2] == lang
  // regex[3] == choice index
  // regex[4] == lang
  const regex = /steps\[(\d+)]\.(?:prompt\[['"](\w+)['"]]|choices\[(\d+)](?:\[['"](\w+)['"]])?)/g

  const parsedPath = regex.exec(errorPath)

  if (parsedPath) {
    if (parsedPath[1]) {
      errorSubject.stepIndex = parsedPath[1]
    }

    if (parsedPath[2] || parsedPath[4]) {
      errorSubject.lang = parsedPath[2] || parsedPath[4]
    }

    if (parsedPath[3]) {
      errorSubject.choiceIndex = parsedPath[3]
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
export const errorsByLang = (quiz: MetaQuestionnaire): {[lang: string]: QuizErrors} => {
  let initialStruct = reduce(quiz.data.languages, (struct, lang) => {
    struct[lang] = {}
    return struct
  }, {})

  return reduce(quiz.errors, (result, currentError, currentErrorPath) => {
    const errorSubject = parseErrorPath(currentErrorPath)

    if (!errorSubject.lang) {
      quiz.data.languages.forEach(lang => {
        result[lang][currentErrorPath] = currentError
      })
    } else {
      result[errorSubject.lang][currentErrorPath] = currentError
    }

    return result
  }, initialStruct)
}

export const langHasErrors = (quiz: MetaQuestionnaire) => (lang: string): boolean => {
  return keys(quiz.errorsByLang[lang] || {}).length > 0
}

export const hasErrors = (quiz: QuestionnaireStore, step: Step) => {
  const errorPath = (index) => `steps[${index}]`

  const stepIndex = findIndex(quiz.data.steps, s => s.id === step.id)
  return stepIndex >= 0 && some(keys(quiz.errors), k => startsWith(k, errorPath(stepIndex)))
}

export const filterByPathPrefix = (errors: QuizErrors, prefix: string) => {
  return reduce(errors, (stepErrors, currentError, currentErrorPath) => {
    if (startsWith(currentErrorPath, prefix)) {
      stepErrors[currentErrorPath] = currentError
    }

    return stepErrors
  }, {})
}

export const stepsPath = 'steps'
export const stepPath = (stepIndex: number) => `${stepsPath}[${stepIndex}]`

export const promptTextPath = (stepIndex: number, mode: string, lang: string): string => {
  let suffix = ''
  if (mode === 'ivr') {
    suffix = `prompt['${lang}'].${mode}.text`
  } else {
    suffix = `prompt['${lang}'].${mode}`
  }

  return `${stepPath(stepIndex)}.${suffix}`
}

export const choicesPath = (stepIndex: number) => `${stepPath(stepIndex)}.choices`
export const choicePath = (stepIndex: number, choiceIndex: number) => `${choicesPath(stepIndex)}[${choiceIndex}]`
export const choiceValuePath = (stepIndex: number, choiceIndex: number) => `${choicePath(stepIndex, choiceIndex)}.value`
export const choiceSmsResponsePath = (stepIndex: number, choiceIndex: number, lang: string) => `${choicePath(stepIndex, choiceIndex)}['${lang}'].sms`
export const choiceIvrResponsePath = (stepIndex: number, choiceIndex: number) => `${choicePath(stepIndex, choiceIndex)}.ivr`

