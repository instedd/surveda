import i18n from '../../i18next'

export const roleDisplayName = (role) => {
  switch (role) {
    case 'admin':
      return i18n.t('Admin')
    case 'editor':
      return i18n.t('Editor')
    case 'reader':
      return i18n.t('Reader')
    case 'owner':
      return i18n.t('Owner')
    default:
      throw new Error(i18n.t('Unknown role: {{role}}', {role}))
  }
}

export const dispositionGroupLabel = (group) => {
  switch (group) {
    case 'responsive':
      return i18n.t('Responsive')
    case 'contacted':
      return i18n.t('Contacted')
    case 'uncontacted':
      return i18n.t('Uncontacted')
    default:
      throw new Error(i18n.t('Unknown group: {{group}}', {group}))
  }
}

export const dispositionLabel = (disposition) => {
  switch (disposition) {
    case 'started':
      return i18n.t('Started')
    case 'rejected':
      return i18n.t('Rejected')
    case 'refused':
      return i18n.t('Refused')
    case 'partial':
      return i18n.t('Partial')
    case 'ineligible':
      return i18n.t('Ineligible')
    case 'completed':
      return i18n.t('Completed')
    case 'breakoff':
      return i18n.t('Breakoff')
    case 'unresponsive':
      return i18n.t('Unresponsive')
    case 'contacted':
      return i18n.t('Contacted')
    case 'registered':
      return i18n.t('Registered')
    case 'queued':
      return i18n.t('Queued')
    case 'failed':
      return i18n.t('Failed')
    default:
      throw new Error(i18n.t('Unknown disposition: {{disposition}}', {disposition}))
  }
}
