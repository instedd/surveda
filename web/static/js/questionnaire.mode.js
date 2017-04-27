// @flow
import isEqual from 'lodash/isEqual'

export const modeLabel = (mode: string | string[]) => {
  if (isEqual(mode, ['sms']) || isEqual(mode, 'sms')) {
    return 'SMS'
  }
  if (isEqual(mode, ['sms', 'ivr'])) {
    return 'SMS with phone call fallback'
  }
  if (isEqual(mode, ['sms', 'mobileweb'])) {
    return 'SMS with Mobile Web fallback'
  }
  if (isEqual(mode, ['ivr']) || isEqual(mode, 'ivr')) {
    return 'Phone call'
  }
  if (isEqual(mode, ['ivr', 'sms'])) {
    return 'Phone call with SMS fallback'
  }
  if (isEqual(mode, ['ivr', 'mobileweb'])) {
    return 'Phone call with Mobile Web fallback'
  }
  if (isEqual(mode, ['mobileweb']) || isEqual(mode, 'mobileweb')) {
    return 'Mobile Web'
  }
  if (isEqual(mode, ['mobileweb', 'sms'])) {
    return 'Mobile Web with SMS fallback'
  }
  if (isEqual(mode, ['mobileweb', 'ivr'])) {
    return 'Mobile Web with phone call fallback'
  }

  return 'Unknown mode'
}

export const modeOrder = (mode: string) => {
  switch (mode) {
    case 'sms': return 0
    case 'ivr': return 1
    case 'mobileweb': return 2
    default: throw new Error(`Unknown mode: ${mode}`)
  }
}
