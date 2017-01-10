// @flow
import deepFreeze from '../../web/static/vendor/js/deepFreeze'
const bareQuestionnaire: Questionnaire = {
  steps: [
    {
      type: 'multiple-choice',
      title: 'Do you smoke?',
      store: 'Smokes',
      id: '17141bea-a81c-4227-bdda-f5f69188b0e7',
      choices: [
        {
          value: 'Yes',
          responses: {
            sms: {
              en: [
                'Yes',
                'Y',
                '1'
              ],
              'es': [
                'Sí',
                'S',
                '1'
              ]
            },
            ivr: [
              '1'
            ]
          },
          skipLogic: null
        },
        {
          value: 'No',
          responses: {
            sms: {
              'en': [
                'No',
                'N',
                '2'
              ],
              'es': [
                'No',
                'N',
                '2'
              ]
            },
            ivr: [
              '2'
            ]
          },
          skipLogic: 'b6588daa-cd81-40b1-8cac-ff2e72a15c15'
        }
      ],
      prompt: {
        'en': {
          sms: 'Do you smoke?',
          ivr: {
            text: 'Do you smoke?',
            audioSource: 'tts'
          }
        },
        'es': {
          sms: 'Fumas?'
        }
      }
    },
    {
      type: 'multiple-choice',
      title: 'Do you exercise?',
      store: 'Exercises',
      id: 'b6588daa-cd81-40b1-8cac-ff2e72a15c15',
      choices: [
        {
          value: 'Yes',
          responses: {
            'en': {
              sms: [
                'Yes',
                'Y',
                '1'
              ],
              ivr: [
                '1'
              ]
            }
          },
          skipLogic: null
        },
        {
          value: 'No',
          responses: {
            'en': {
              sms: [
                'No',
                'N',
                '2'
              ],
              ivr: [
                '2'
              ]
            }
          },
          skipLogic: null
        }
      ],
      prompt: {
        'en': {
          sms: 'Do you exercise?'
        },
        'es': {
          sms: 'Ejercitas?'
        }
      }
    }
  ],
  projectId: 1,
  name: 'Foo',
  modes: [
    'sms', 'ivr'
  ],
  id: 1,
  defaultLanguage: 'en',
  activeLanguage: 'en',
  languages: ['en'],
  quotaCompletedMsg: {},
  errorMsg: {}
}

// TODO: investigate why Flow ignores the result of `deepFreeze`
// It probably is defined as `any` somewhere.
// As a workaround, we define `bareQuestionnaire` and explicitly annotate it as
// Questionnaire. That will let us catch inconsistencies when we define the
// Questionnaire fixture for testing here.
// The limitations of deepFreeze are probably related to sealed objects being used under its hood.
// See: https://flowtype.org/docs/objects.html#sealed-object-types
export const questionnaire: Questionnaire = deepFreeze(bareQuestionnaire)
