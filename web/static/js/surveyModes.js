// @flow
import flatten from 'lodash/flatten'
import isEqual from 'lodash/isEqual'
import some from 'lodash/some'

function modeIncludes(modes, target) {
  return some(modes, ary => isEqual(ary, target))
}

export function availableOptions(surveyModes: Array<Array<string>>) {
  const allModes = ['sms', 'ivr', 'mobileweb']
  const availableOptions = flatten(allModes.map((primary) => {
    return allModes.map((fallback) => {
      return (primary == fallback) ? [primary] : [primary, fallback]
    })
  }))
  return (availableOptions.filter((mode) => {
    return !modeIncludes(surveyModes, mode)
  }))
}
