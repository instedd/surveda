// @flow
import flatten from 'lodash/flatten'
import isEqual from 'lodash/isEqual'
import some from 'lodash/some'

export function modeIncludes(modes: Array<Array<string>>, target: string) {
  return some(modes, ary => isEqual(ary, target))
}

export function availableOptions(surveyModes: Array<Array<string>>) {
  const options = allOptions()
  return (options.filter((mode) => {
    return !modeIncludes(surveyModes, mode)
  }))
}

export function allOptions() {
  const modes = ['sms', 'ivr', 'mobileweb']
  return flatten(modes.map((primary) => {
    return modes.map((fallback) => {
      return (primary == fallback) ? [primary] : [primary, fallback]
    })
  }))
}
