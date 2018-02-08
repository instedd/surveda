import i18n from 'i18next'
// import LanguageDetector from 'i18next-browser-languagedetector'

i18n
  // .use(LanguageDetector)
  .init({
    // we init with resources
    resources: {
      en: {
        translations: {
          'Name': 'Name',
          'Running surveys': 'Running surveys',
          'Last activity date': 'Last activity date'
        }
      },
      es: {
        translations: {
          'Name': 'Nombre',
          'Running surveys': 'Encuestas corriendo',
          'Last activity date': 'Fecha de última actividad',
          ' project': ' proyecto',
          ' projects': ' proyectos'
        }
      }
    },
    fallbackLng: 'en',

    // have a common namespace used around the full app
    ns: ['translations'],
    defaultNS: 'translations',

    keySeparator: false, // we use content as keys

    interpolation: {
      escapeValue: false, // not needed for react!!
      formatSeparator: ','
    },

    react: {
      wait: true
    }
  })

export default i18n
