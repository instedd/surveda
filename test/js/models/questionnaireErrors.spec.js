/* eslint-env mocha */
// @flow
import expect from 'expect'
import { questionnaire } from '../fixtures'
import { hasErrors } from '../../../web/static/js/questionnaireErrors'

describe('questionnaire error', () => {
  describe('hasErrors', () => {
    it('should report errors', () => {
      const step = questionnaire.steps[0]
      const quiz = {
        data: questionnaire,
        errors: {
          'steps[0].andsomeprefix': ['Some error message']
        },
        errorsByLang: {
          'en': {
            'steps[0].andsomeprefix': ['Some error message']
          }
        }
      }

      const result = hasErrors(quiz, step)

      expect(result).toEqual(true)
    })

    it('should report no error', () => {
      const step = questionnaire.steps[0]
      const quiz = {
        data: questionnaire,
        errors: {
          'steps[1].andsomeprefix': ['Some error message']
        },
        errorsByLang: {}
      }

      const result = hasErrors(quiz, step)

      expect(result).toEqual(false)
    })
  })
})
