import i18n from 'i18next'
import english from '../../../locales/translations/en.json'
import spanish from '../../../locales/translations/es.json'
import french from '../../../locales/translations/fr.json'
import { config } from './config'
const currentLanguage = config.user_settings.language || 'en'

i18n
  .init({
    // we init with resources
    resources: {
      en: {
        translations: english
      },
      es: {
        translations: spanish
      },
      fr: {
        translations: french
      }
    },
    fallbackLng: 'en',
    lng: currentLanguage,

    // have a common namespace used around the full app
    ns: ['translations'],
    defaultNS: 'translations',

    keySeparator: false, // we use content as keys
    nsSeparator: false,

    interpolation: {
      escapeValue: false, // not needed for react!!
      formatSeparator: ','
    },

    react: {
      wait: true
    }
  })

export default i18n
