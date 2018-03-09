// @flow
import isEqual from 'lodash/isEqual'
import i18n from './i18next'

export const modeLabel = (mode: string | string[]) => {
  if (isEqual(mode, ['sms']) || isEqual(mode, 'sms')) {
    return i18n.t('SMS')
  }
  if (isEqual(mode, ['sms', 'ivr'])) {
    return i18n.t('SMS with phone call fallback')
  }
  if (isEqual(mode, ['sms', 'mobileweb'])) {
    return i18n.t('SMS with mobile web fallback')
  }
  if (isEqual(mode, ['ivr']) || isEqual(mode, 'ivr')) {
    return i18n.t('Phone call')
  }
  if (isEqual(mode, ['ivr', 'sms'])) {
    return i18n.t('Phone call with SMS fallback')
  }
  if (isEqual(mode, ['ivr', 'mobileweb'])) {
    return i18n.t('Phone call with mobile web fallback')
  }
  if (isEqual(mode, ['mobileweb']) || isEqual(mode, 'mobileweb')) {
    return i18n.t('Mobile Web')
  }
  if (isEqual(mode, ['mobileweb', 'sms'])) {
    return i18n.t('Mobile Web with SMS fallback')
  }
  if (isEqual(mode, ['mobileweb', 'ivr'])) {
    return i18n.t('Mobile Web with phone call fallback')
  }

  return i18n.t('Unknown mode: {{mode}}', {mode})
}

export const modeOrder = (mode: string) => {
  switch (mode) {
    case 'sms': return 0
    case 'ivr': return 1
    case 'mobileweb': return 2
    default: throw new Error(i18n.t('Unknown mode: {{mode}}', {mode}))
  }
}

export const defaultActiveMode = (modes: string[]) => {
  if (modes.indexOf('sms') != -1) return 'sms'
  if (modes.indexOf('ivr') != -1) return 'ivr'
  if (modes.indexOf('mobileweb') != -1) return 'mobileweb'
  if (modes.length > 0) return modes[0]
  return null
}
