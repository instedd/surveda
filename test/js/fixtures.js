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
            ],
            mobileweb: {
              'en': 'Of course',
              'es': 'Por supuesto'
            }
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
            ],
            mobileweb: {
              'en': 'Not at all',
              'es': 'Para nada'
            }
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
          },
          mobileweb: 'Do you really smoke?'
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
  quotaCompletedSteps: null,
  projectId: 1,
  name: 'Foo',
  modes: [
    'sms', 'ivr'
  ],
  id: 1,
  defaultLanguage: 'en',
  activeLanguage: 'en',
  activeMode: 'sms',
  languages: ['en'],
  settings: {
    errorMessage: {},
    mobileWebSmsMessage: '',
    mobileWebSurveyIsOverMessage: '',
    title: {},
    mobileWebColorStyle: {},
    surveyAlreadyTakenMessage: {}
  },
  valid: true
}

// TODO: investigate why Flow ignores the result of `deepFreeze`
// It probably is defined as `any` somewhere.
// As a workaround, we define `bareQuestionnaire` and explicitly annotate it as
// Questionnaire. That will let us catch inconsistencies when we define the
// Questionnaire fixture for testing here.
// The limitations of deepFreeze are probably related to sealed objects being used under its hood.
// See: https://flowtype.org/docs/objects.html#sealed-object-types
export const questionnaire: Questionnaire = deepFreeze(bareQuestionnaire)

const bareSurvey: Survey = {
  id: 1,
  projectId: 1,
  name: 'Foo',
  cutoff: 123,
  countPartialResults: false,
  state: 'ready',
  exitCode: 0,
  exitMessage: null,
  questionnaireIds: [1],
  schedule: {
    dayOfWeek: {'sun': true, 'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true, 'sat': true},
    startTime: '02:00:00',
    endTime: '06:00:00',
    timezone: 'Etc/UTC',
    blockedDays: []
  },
  channels: [1],
  respondentsCount: 2,
  comparisons: [],
  ivrRetryConfiguration: '',
  mobilewebRetryConfiguration: '',
  smsRetryConfiguration: '',
  fallbackDelay: '',
  modeComparison: false,
  questionnaireComparison: false,
  quotas: {
    vars: [],
    buckets: []
  },
  mode: [['sms']],
  nextScheduleTime: null
}

export const survey: Survey = deepFreeze(bareSurvey)

const bareChannel: Channel = {
  id: 1,
  userId: 1,
  name: 'Channel Name',
  type: 'sms',
  provider: 'nuntium',
  settings: {
    nuntiumChannel: 'Nuntium Channel Name'
  }
}

export const channel: Channel = deepFreeze(bareChannel)

const bareProject: Project = {
  id: 1,
  name: 'Project Name',
  updatedAt: '2017-01-10T21:03:19'
}

export const project: Project = deepFreeze(bareProject)
