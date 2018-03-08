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
