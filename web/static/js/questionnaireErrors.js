// @flow
import findIndex from 'lodash/findIndex'
import keys from 'lodash/keys'
import some from 'lodash/some'
import startsWith from 'lodash/startsWith'

export const hasErrors = (quiz: MetaQuestionnaire, step: Step) => {
  const errorPath = (index) => `steps[${index}]`

  const stepIndex = findIndex(quiz.data.steps, s => s.id === step.id)
  return stepIndex >= 0 && some(keys(quiz.errors), k => startsWith(k, errorPath(stepIndex)))
}
