/* eslint-env mocha */
// @flow
import expect from 'expect'
import assert from 'assert'
import { playActionsFromState } from '../spec_helper'
import find from 'lodash/find'
import deepFreeze from '../../../web/static/vendor/js/deepFreeze'
import reducer, { stepStoreValues, csvForTranslation, csvTranslationFilename } from '../../../web/static/js/reducers/questionnaire'
import { questionnaire } from '../fixtures'
import * as actions from '../../../web/static/js/actions/questionnaire'
import isEqual from 'lodash/isEqual'
import { smsSplitSeparator } from '../../../web/static/js/step'

describe('questionnaire reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should update questionnaire with new name', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.changeName('Some other name')
    ])

    expect(result.data.name).toEqual('Some other name')
  })

  describe('fetching', () => {
    it('has a sane initial state', () => {
      expect(initialState.fetching).toEqual(false)
      expect(initialState.filter).toEqual(null)
      expect(initialState.data).toEqual(null)
      expect(initialState.dirty).toEqual(false)
      expect(initialState.saving).toEqual(false)
    })

    it('receives a questionnaire', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire)
      ])
      expect(state.fetching).toEqual(false)
      expect(state.data).toEqual({
        ...questionnaire,
        valid: false
      })
    })

    it('should fetch', () => {
      assert(!actions.shouldFetch({fetching: true, filter: {projectId: 1, id: 1}}, 1, 1))
      assert(actions.shouldFetch({fetching: true, filter: null}, 1, 1))
      assert(actions.shouldFetch({fetching: true, filter: {projectId: 1, id: 1}}, 2, 2))
      assert(actions.shouldFetch({fetching: false, filter: null}, 1, 1))
      assert(actions.shouldFetch({fetching: false, filter: {projectId: 1, id: 1}}, 1, 1))
    })

    it('fetches a questionnaire', () => {
      const state = playActions([
        actions.fetch(1, 1)
      ])

      expect(state).toEqual({
        ...state,
        fetching: true,
        filter: {
          projectId: 1,
          id: 1
        },
        data: null
      })
    })

    it('clears data when fetching a different questionnaire', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.fetch(2, 2)
      ])

      expect(state).toEqual({
        ...state,
        fetching: true,
        filter: {
          projectId: 2,
          id: 2
        },
        data: null
      })
    })

    it('keeps old data when fetching new data for the same filter', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.fetch(1, 1)
      ])

      expect(state).toEqual({
        ...state,
        fetching: true,
        data: {
          ...questionnaire,
          valid: false
        }
      })
    })

    it('ignores data received based on different filter', () => {
      const state = playActions([
        actions.fetch(2, 2),
        actions.receive(questionnaire)
      ])

      expect(state).toEqual({
        ...state,
        fetching: true,
        data: null
      })
    })
  })

  describe('autosaving', () => {
    it('updating questionnaire should mark it as dirty', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeName('  Some other name  ')
      ])

      expect(state.data.name).toEqual('Some other name')

      expect(state).toEqual({
        ...state,
        dirty: true
      })
    })

    it('should be marked saving when saving', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeName('Some other name'),
        actions.saving()
      ])

      expect(state).toEqual({
        ...state,
        dirty: false,
        saving: true
      })
    })

    it('should be marked clean and saved when saved', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeName('Some other name'),
        actions.saving(),
        actions.saved()
      ])

      expect(state).toEqual({
        ...state,
        saving: false,
        dirty: false
      })
    })
  })

  describe('modes', () => {
    it('should toggle mode', () => {
      const result = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr')
      ])

      expect(result.data.modes.length).toEqual(1)
      expect(result.data.modes).toEqual(['sms'])
    })

    it('should toggle other mode', () => {
      const result = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('sms'),
        actions.toggleMode('ivr')
      ])

      /* Expectations on arrays must include a check for length
      because for JS 'Foo,Bar' == ['Foo', 'Bar']        -_- */
      expect(result.data.modes.length).toEqual(0)
    })

    it('should toggle modes multiple times', () => {
      const result = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.toggleMode('sms'),
        actions.toggleMode('sms')
      ])

      /* Expectations on arrays must include a check for length
      because for JS 'Foo,Bar' == ['Foo', 'Bar']        -_- */
      expect(result.data.modes.length).toEqual(1)
      expect(result.data.modes).toEqual(['sms'])
    })

    it('should toggle mobileweb mode on', () => {
      const result = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb')
      ])
      expect(result.data.modes).toInclude(['mobileweb'])
    })

    it('should toggle mobileweb mode off', () => {
      const result = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb'),
        actions.toggleMode('mobileweb')
      ])
      expect(result.data.modes).toExclude(['mobileweb'])
    })
  })

  describe('steps', () => {
    it('should add step', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire)
      ])

      const resultState = playActionsFromState(preState, reducer)([
        actions.addStep()
      ])

      const newStep = resultState.data.steps[resultState.data.steps.length - 1]

      expect(resultState.data.steps.length).toEqual(preState.data.steps.length + 1)
      expect(newStep.type).toEqual('multiple-choice')
    })

    it('should change step type', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepType('17141bea-a81c-4227-bdda-f5f69188b0e7', 'numeric')
      ])

      const resultStep = find(preState.data.steps, s => s.id === '17141bea-a81c-4227-bdda-f5f69188b0e7')

      expect(preState.data.steps.length).toEqual(preState.data.steps.length)
      expect(resultStep.type).toEqual('numeric')
      expect(resultStep.title).toEqual('Do you smoke?')
      expect(resultStep.store).toEqual('Smokes')
      expect(resultStep.prompt['en']).toEqual({
        sms: 'Do you smoke?',
        ivr: { audioSource: 'tts', text: 'Do you smoke?' },
        mobileweb: 'Do you really smoke?'
      })
    })

    it('should update step title', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepTitle('b6588daa-cd81-40b1-8cac-ff2e72a15c15', '  New title  ')
      ])

      expect(preState.data.steps.length).toEqual(preState.data.steps.length)
      const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.title).toEqual('New title')
    })

    it('should update step prompt sms', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptSms('b6588daa-cd81-40b1-8cac-ff2e72a15c15', '  New prompt  ')]
      )

      const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.prompt['en'].sms).toEqual('New prompt')
    })

    it('should update step prompt ivr', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptIvr('b6588daa-cd81-40b1-8cac-ff2e72a15c15', {text: '  New prompt  ', audioSource: 'tts'})]
      )

      const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.prompt['en'].ivr).toEqual({text: 'New prompt', audioSource: 'tts'})
    })

    it('should update step prompt mobileweb', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptMobileWeb('b6588daa-cd81-40b1-8cac-ff2e72a15c15', '  New prompt  ')]
      )

      const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.prompt['en'].mobileweb).toEqual('New prompt')
    })

    it('should update step store', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepStore('b6588daa-cd81-40b1-8cac-ff2e72a15c15', '  New store  ')]
      )

      const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.store).toEqual('New store')
    })

    it('should delete step', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire)
      ])

      const preSteps = preState.data.steps

      const resultState = playActionsFromState(preState, reducer)([
        actions.deleteStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      ])

      const steps = resultState.data.steps

      const deletedStep = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')

      expect(steps.length).toEqual(preSteps.length - 1)
      expect(deletedStep).toEqual(null)
      expect(steps[0].title).toEqual('Do you smoke?')
    })

    it('should move step under another step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.moveStep('17141bea-a81c-4227-bdda-f5f69188b0e7', 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      ])

      expect(questionnaire.steps.length).toEqual(state.data.steps.length)
      expect(questionnaire.steps[0]).toEqual(state.data.steps[1])
      expect(questionnaire.steps[1]).toEqual(state.data.steps[0])
    })

    it('should move step to top', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.moveStepToTop('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      ])

      expect(questionnaire.steps.length).toEqual(state.data.steps.length)
      expect(questionnaire.steps[0]).toEqual(state.data.steps[1])
      expect(questionnaire.steps[1]).toEqual(state.data.steps[0])
    })

    describe('choices', () => {
      it('should add choice', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15')]
        )

        const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
        expect(step.choices.length).toEqual(3)
        expect(step.choices[2].value).toEqual('')
        expect(step.choices[2].responses).toEqual({sms: {'en': []}, ivr: []})
      })

      it('should delete choice', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.deleteChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 1)]
        )

        const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
        expect(step.choices.length).toEqual(1)
        expect(step.choices[0].value).toEqual('Yes')
      })

      it('should modify choice', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, '  Maybe  ', '  M,  MB  , 3  ', '  May  ', 'M', 'end')
        ])

        const step = find(preState.data.steps, s => s.id === '17141bea-a81c-4227-bdda-f5f69188b0e7')
        expect(step.choices.length).toEqual(2)
        expect(step.choices[1].value).toEqual('Maybe')
        expect(step.choices[1].skipLogic).toEqual('end')
        expect(step.choices[1].responses.ivr).toEqual('May')
        expect(step.choices[1].responses.sms['en']).toEqual([
          'M',
          'MB',
          '3'
        ])
        expect(step.choices[1].responses.mobileweb['en']).toEqual('M')
      })

      it('should autocomplete choice sms values', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.setActiveLanguage('es'),
          actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, '', '', '', 'end'),
          actions.autocompleteChoiceSmsValues('17141bea-a81c-4227-bdda-f5f69188b0e7', 1,
            {text: '  M,  MB  , 3  ', translations: [{language: 'es', text: '  A, B , C '}, {language: null, text: null}]})
        ])

        const step = find(preState.data.steps, s => s.id === '17141bea-a81c-4227-bdda-f5f69188b0e7')
        expect(step.choices[1].responses.sms['en']).toEqual([
          'M',
          'MB',
          '3'
        ])
        expect(step.choices[1].responses.sms['es']).toEqual([
          'A',
          'B',
          'C'
        ])
      })

      it('should autocomplete choice options when parameter is true', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'M', 'end'),
          actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
          actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', '', '', 'M', 'some-id', true)
        ])

        const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
        expect(step.choices.length).toEqual(3)
        expect(step.choices[2]).toEqual({
          value: 'Maybe',
          responses: {
            ivr: ['May'],
            sms: {
              'en': [
                'M',
                'MB',
                '3'
              ]
            },
            mobileweb: {
              'en': 'M'
            }
          },
          skipLogic: 'some-id'
        })
      })

      it('should not autocomplete choice options when not asked to', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'end'),
          actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
          actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', '', '', '', 'some-other-id', false)
        ])

        const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
        expect(step.choices.length).toEqual(3)
        expect(step.choices[2]).toEqual({
          value: 'Maybe',
          responses: {
            ivr: [],
            sms: {
              'en': []
            },
            mobileweb: {
              'en': ''
            }
          },
          skipLogic: 'some-other-id'
        })
      })

      it('should not autocomplete choice options when there are options already set', () => {
        const preState = playActions([
          actions.fetch(1, 1),
          actions.receive(questionnaire),
          actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'M', 'end'),
          actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
          actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', 'Perhaps', '2, 3', 'M', 'some-other-id', true)
        ])

        const step = find(preState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
        expect(step.choices.length).toEqual(3)

        expect(step.choices[2]).toEqual({
          value: 'Maybe',
          responses: {
            ivr: ['2', '3'],
            sms: {
              'en': [
                'Perhaps'
              ]
            },
            mobileweb: {
              'en': 'M'
            }
          },
          skipLogic: 'some-other-id'
        })
      })
    })
  })

  describe('validations', () => {
    it('should validate SMS message must not be blank if "SMS" mode is on', () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.addLanguage('es'),
        actions.addLanguage('fr'),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', ''),
        actions.setActiveLanguage('es'),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', 'Hola!'),
        actions.setActiveLanguage('fr'),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', '')
      ])

      const errors = resultState.errors
      expect(errors).toInclude({
        path: "steps[1].prompt['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'SMS prompt must not be blank'
      })

      expect(errors).toInclude({
        path: "steps[1].prompt['fr'].sms",
        lang: 'fr',
        mode: 'sms',
        message: 'SMS prompt must not be blank'
      })

      expect(resultState.errorsByPath).toInclude({
        "steps[1].prompt['en'].sms": ['SMS prompt must not be blank'],
        "steps[1].prompt['fr'].sms": ['SMS prompt must not be blank']
      })

      expect(resultState.errorsByLang).toInclude({
        'en': true,
        'fr': true
      })
    })

    it('should validate mobileweb message must not be blank if mobileweb mode is on', () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb'),
        actions.changeStepPromptMobileWeb('17141bea-a81c-4227-bdda-f5f69188b0e7', '')
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].prompt['en'].mobileweb",
        lang: 'en',
        mode: 'mobileweb',
        message: 'Mobile web prompt must not be blank'
      })
    })

    it('should include an error error if SMS prompt exceeds the character limit', () => {
      const smsPropmpt = new Array(200).join('a')

      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', smsPropmpt)
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].prompt['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'limit exceeded'
      })
    })

    it('should include an error if a part of the SMS prompt exceeds the character limit', () => {
      const smsPrompt = new Array(200).join('a') + smsSplitSeparator + new Array(30).join('b')
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', smsPrompt)
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].prompt['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'limit exceeded'
      })
    })

    it('should not include an error if none of the parts of the SMS prompt exceed the character limit', () => {
      const smsPrompt = new Array(50).join('a') + smsSplitSeparator + new Array(30).join('b')
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptSms('17141bea-a81c-4227-bdda-f5f69188b0e7', smsPrompt)
      ])

      expect(resultState.errors).toExclude({
        [`steps[0].prompt['en'].sms`]: ['SMS prompt is too long']
      })
    })

    it('should include an error if mobile web sms message prompt exceeds the character limit', () => {
      const prompt = 'a'.repeat(141)

      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb'),
        actions.setMobileWebSmsMessage(prompt)
      ])

      expect(resultState.errors).toInclude({
        path: 'mobileWebSmsMessage',
        lang: null,
        mode: 'mobileweb',
        message: 'limit exceeded'
      })
    })

    it('should validate voice message must not be blank if "Phone call" mode is on', () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('sms'),
        actions.addLanguage('es'),
        actions.addLanguage('fr'),
        actions.changeStepPromptIvr('17141bea-a81c-4227-bdda-f5f69188b0e7', {text: '', audioSource: 'tts'}),
        actions.setActiveLanguage('es'),
        actions.changeStepPromptIvr('17141bea-a81c-4227-bdda-f5f69188b0e7', {text: 'Hola!', audioSource: 'tts'}),
        actions.setActiveLanguage('fr'),
        actions.changeStepPromptIvr('17141bea-a81c-4227-bdda-f5f69188b0e7', {text: '', audioSource: 'tts'})
      ])

      const errors = resultState.errors
      expect(errors).toInclude({
        path: "steps[1].prompt['en'].ivr.text",
        lang: 'en',
        mode: 'ivr',
        message: 'Voice prompt must not be blank'
      })
      expect(errors).toInclude({
        path: "steps[1].prompt['fr'].ivr.text",
        lang: 'fr',
        mode: 'ivr',
        message: 'Voice prompt must not be blank'
      })
    })

    it('should validate required audioId for prompt ivr when audio source is upload', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptIvr('b6588daa-cd81-40b1-8cac-ff2e72a15c15', {text: '  New prompt  ', audioSource: 'upload'})]
      )

      expect(state.errors).toInclude({
        path: "steps[1].prompt['en'].ivr.audioId",
        lang: 'en',
        mode: 'ivr',
        message: 'An audio file must be uploaded'
      })
    })

    it('should validate there must be at least two responses', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.deleteChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0),
        actions.deleteChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0)
      ])

      expect(state.errors).toInclude({
        path: 'steps[0].choices',
        lang: null,
        mode: null,
        message: 'You should define at least two response options'
      })
    })

    it("should validate a response's response must not be blank", () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, '', 'a', 'a', '1', null)
      ])

      expect(state.errors).toInclude({
        path: 'steps[0].choices[0].value',
        lang: null,
        mode: null,
        message: 'Response must not be blank'
      })
    })

    it("should validate a response's SMS must not be blank if SMS mode is on", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', '', 'a', '1', null),
        actions.addLanguage('es'),
        actions.setActiveLanguage('es'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'a', 'a', '1', null),
        actions.addLanguage('fr'),
        actions.setActiveLanguage('fr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', '', 'a', '1', null)
      ])

      const errors = resultState.errors
      expect(errors).toInclude({
        path: "steps[1].choices[0]['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'SMS must not be blank'
      })

      expect(errors).toInclude({
        path: "steps[1].choices[0]['fr'].sms",
        lang: 'fr',
        mode: 'sms',
        message: 'SMS must not be blank'
      })
    })

    it("should validate a response's SMS must not be STOP if SMS mode is on", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'stop', 'a', '1', null),
        actions.addLanguage('es'),
        actions.setActiveLanguage('es'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'a', 'a', '1', null),
        actions.addLanguage('fr'),
        actions.setActiveLanguage('fr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'stop', 'a', '1', null)
      ])

      const errors = resultState.errors
      expect(errors).toInclude({
        path: "steps[1].choices[0]['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: "SMS must not be 'STOP'"
      })
      expect(errors).toInclude({
        path: "steps[1].choices[0]['fr'].sms",
        lang: 'fr',
        mode: 'sms',
        message: "SMS must not be 'STOP'"
      })
    })

    it("should validate a response's Mobile Web must not be blank if Mobile Web mode is on", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'a', '', '', null)
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].choices[0]['en'].mobileweb",
        lang: 'en',
        mode: 'mobileweb',
        message: 'Mobile web must not be blank'
      })
    })

    it("should validate a response's Phone call must not be blank if Voice mode is on", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('sms'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'b', '', '', null),
        actions.addLanguage('es'),
        actions.setActiveLanguage('es'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'b', '', '', null),
        actions.addLanguage('fr'),
        actions.setActiveLanguage('fr'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'b', '', '', null)
      ])

      expect(resultState.errors).toInclude({
        path: 'steps[1].choices[0].ivr',
        lang: null,
        mode: 'ivr',
        message: '"Phone call" must not be blank'
      })
    })

    it("should validate a response's Phone call must only consist of digits or # or *", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'M', 'end'),
        actions.changeStepPromptIvr('b6588daa-cd81-40b1-8cac-ff2e72a15c15', {text: 'Some IVR prompt'}),
        actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
        actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', 'A', '3, b, #, 22', 'M', 'some-other-id', false)
      ])

      const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
      expect(step.choices.length).toEqual(3)
      expect(step.choices[2]).toEqual({
        value: 'Maybe',
        responses: {
          ivr: [
            '3',
            'b',
            '#',
            '22'
          ],
          sms: {
            'en': ['A']
          },
          mobileweb: {
            'en': 'M'
          }
        },
        skipLogic: 'some-other-id'
      })

      const errors = resultState.errors
      expect(errors).toInclude({
        path: 'steps[0].choices[1].ivr',
        lang: null,
        mode: 'ivr',
        message: '"Phone call" must only consist of single digits, "#" or "*"'
      })
      expect(errors).toInclude({
        path: 'steps[1].choices[2].ivr',
        lang: null,
        mode: 'ivr',
        message: '"Phone call" must only consist of single digits, "#" or "*"'
      })
    })

    it("should validate a response's 'response' can't appear more than once in a same step", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptIvr(questionnaire.steps[1].id, {text: 'Some IVR Prompt'}),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'dup', 'b', '1', 'b', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'dup', 'c', '2', 'c', null)
      ])

      expect(resultState.errors).toInclude({
        path: 'steps[0].choices[1].value',
        lang: null,
        mode: null,
        message: 'Value already used in a previous response'
      })
    })

    it("should validate a response's SMS value must not overlap other SMS values", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptIvr(questionnaire.steps[1].id, {text: 'Some IVR Prompt'}),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'b, c', '1', 'b', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'b', 'd, c', '2', 'b', null)
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].choices[1]['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'Value "c" already used in a previous response'
      })
    })

    it("should not validate response's SMS duplicate values if SMS mode is disabled", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('sms'),
        actions.changeStepPromptIvr(questionnaire.steps[1].id, {text: 'Some IVR Prompt'}),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'b, c', '1', 'b', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'b', 'd, c', '2', 'b', null)
      ])

      expect(resultState.errors).toNotInclude({
        [`steps[0].choices[1]['en'].sms`]: ['Value "c" already used in a previous response']
      })
    })

    it("should validate a response's IVR value must not overlap other IVR values", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeStepPromptIvr(questionnaire.steps[1].id, {text: 'Some IVR Prompt'}),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'x', '1, 2', 'x', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'b', 'y', '3, 2', 'y', null)
      ])

      expect(resultState.errors).toInclude({
        path: 'steps[0].choices[1].ivr',
        lang: null,
        mode: 'ivr',
        message: 'Value "2" already used in a previous response'
      })
    })

    it("should validate a response's IVR duplicate value if IVR mode is disabled", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('ivr'),
        actions.changeStepPromptIvr(questionnaire.steps[1].id, {text: 'Some IVR Prompt'}),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'x', '1, 2', 'a', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'b', 'y', '3, 2', 'b', null)
      ])

      expect(resultState.errors).toNotInclude({
        'steps[0].choices[1].ivr': ['Value "2" already used in a previous response']
      })
    })

    it("should validate a response's mobile web value must not overlap other mobile web values", () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb'),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, 'a', 'x', '1', 'b', null),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'b', 'y', '2', 'b', null)
      ])

      expect(resultState.errors).toInclude({
        path: "steps[0].choices[1]['en'].mobileweb",
        lang: 'en',
        mode: 'mobileweb',
        message: 'Value "b" already used in a previous response'
      })
    })

    it('should validate error message SMS prompt must not be blank if SMS mode is on', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setSmsQuestionnaireMsg('errorMsg', '')
      ])

      expect(state.errors).toInclude({
        path: "errorMsg.prompt['en'].sms",
        lang: 'en',
        mode: 'sms',
        message: 'SMS prompt must not be blank'
      })
    })

    it('should validate error message IVR prompt must not be blank if IVR mode is on', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setIvrQuestionnaireMsg('errorMsg', {text: '', audioSource: 'tts'})
      ])

      expect(state.errors).toInclude({
        path: `errorMsg.prompt['en'].ivr.text`,
        lang: 'en',
        mode: 'ivr',
        message: 'Voice prompt must not be blank'
      })
    })

    it('should validate quota completed message SMS prompt must not be blank if SMS mode is on', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', '')
      ])

      expect(state.errors).toInclude({
        path: `quotaCompletedMsg.prompt['en'].sms`,
        lang: 'en',
        mode: 'sms',
        message: 'SMS prompt must not be blank'
      })
    })

    it('should validate quota completed message Mobile Web prompt must not be blank if Mobile Web mode is on', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.toggleMode('mobileweb')
      ])

      expect(state.errors).toInclude({
        path: "quotaCompletedMsg.prompt['en'].mobileweb",
        lang: 'en',
        mode: 'mobileweb',
        message: 'Mobile web prompt must not be blank'
      })
    })

    it('should validate quota completed message IVR prompt must not be blank if IVR mode is on', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', '')
      ])

      expect(state.errors).toInclude({
        path: "quotaCompletedMsg.prompt['en'].ivr.text",
        lang: 'en',
        mode: 'ivr',
        message: 'Voice prompt must not be blank'
      })
    })

    it('should consider "end" skip logic as valid', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 0, '  Maybe  ', '  M,  MB  , 3  ', '  May  ', 'end')
      ])

      for (const error of state.errors) {
        expect(error.path).toExclude('skipLogic')
      }
    })

    it('should validate language selection step prompt', () => {
      const resultState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        // actions.toggleMode('ivr'),
        actions.toggleMode('mobileweb')
      ])

      const errors = resultState.errors
      expect(errors).toInclude({
        path: 'steps[0].prompt.sms',
        lang: null,
        mode: 'sms',
        message: 'SMS prompt must not be blank'
      })
      expect(errors).toInclude({
        path: 'steps[0].prompt.ivr.text',
        lang: null,
        mode: 'ivr',
        message: 'Voice prompt must not be blank'
      })
      expect(errors).toInclude({
        path: 'steps[0].prompt.mobileweb',
        lang: null,
        mode: 'mobileweb',
        message: 'Mobile web prompt must not be blank'
      })
    })
  })

  describe('multilanguage support', () => {
    it('should add language selection step when adding a language', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr')
      ])

      const languageSelection = preState.data.steps[0]
      expect(languageSelection.type).toEqual('language-selection')
      expect(languageSelection.languageChoices).toInclude('fr')
    })

    it('should allow edition of ivr message for language selection step when switching default language', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.addLanguage('es'),
        actions.setDefaultLanguage('es')
      ])

      const languageSelection = preState.data.steps[0]
      const finalResultState = playActionsFromState(preState, reducer)([
        actions.changeStepPromptIvr(languageSelection.id, {text: 'New language prompt', audioSource: 'tts'})
      ])
      const finalLanguageSelection = finalResultState.data.steps[0]
      expect(finalLanguageSelection.prompt.ivr).toEqual({text: 'New language prompt', audioSource: 'tts'})
    })

    it('should allow edition of sms message for language selection step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr')
      ])

      const languageSelection = state.data.steps[0]
      const finalResultState = playActionsFromState(state, reducer)([
        actions.changeStepPromptSms(languageSelection.id, 'New language prompt')
      ])
      const finalLanguageSelection = finalResultState.data.steps[0]
      expect(finalLanguageSelection.prompt.sms).toEqual('New language prompt')
    })

    it('should allow edition of mobile web message for language selection step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr')
      ])

      const languageSelection = state.data.steps[0]
      const finalResultState = playActionsFromState(state, reducer)([
        actions.changeStepPromptMobileWeb(languageSelection.id, 'New language prompt')
      ])
      const finalLanguageSelection = finalResultState.data.steps[0]
      expect(finalLanguageSelection.prompt.mobileweb).toEqual('New language prompt')
    })

    it('should update step prompt ivr on a new step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.setDefaultLanguage('es'),
        actions.addStep()
      ])

      const newStep = state.data.steps[state.data.steps.length - 1]

      const finalState = playActionsFromState(state, reducer)([
        actions.changeStepPromptIvr(newStep.id, {text: 'Nuevo prompt', audioSource: 'tts'})]
      )

      const step = find(finalState.data.steps, s => s.id === newStep.id)
      expect(step.prompt['es'].ivr).toEqual({text: 'Nuevo prompt', audioSource: 'tts'})
    })

    it('should update step prompt mobile web on a new step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.setDefaultLanguage('es'),
        actions.addStep()
      ])

      const newStep = state.data.steps[state.data.steps.length - 1]

      const finalState = playActionsFromState(state, reducer)([
        actions.changeStepPromptMobileWeb(newStep.id, 'nuevo prompt')
      ])

      const step = find(finalState.data.steps, s => s.id === newStep.id)
      expect(step.prompt['es'].mobileweb).toEqual('nuevo prompt')
    })

    it('should update step audioId ivr on a new step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.setDefaultLanguage('es'),
        actions.addStep()
      ])

      const newStep = state.data.steps[state.data.steps.length - 1]

      const finalState = playActionsFromState(state, reducer)([
        actions.changeStepAudioIdIvr(newStep.id, '1234')]
      )

      const step = find(finalState.data.steps, s => s.id === newStep.id)
      expect(step.prompt['es'].ivr).toEqual({text: '', audioId: '1234', audioSource: 'upload'})
    })

    it('should add a new language last inside the choices of the language selection step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('en'),
        actions.addLanguage('de')
      ])

      const languageSelection = state.data.steps[0]
      expect(languageSelection.languageChoices[languageSelection.languageChoices.length - 1]).toEqual('de')
    })

    it('should remove a language inside the choices of the language selection step', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('en'),
        actions.addLanguage('de'),
        actions.addLanguage('es'),
        actions.addLanguage('fr')
      ])
      const preLanguageSelection = preState.data.steps[0]
      expect(preLanguageSelection.languageChoices[1]).toEqual('de')

      const resultState = playActionsFromState(preState, reducer)([
        actions.removeLanguage('de')
      ])

      const languageSelection = resultState.data.steps[0]
      expect(languageSelection.languageChoices[1]).toEqual('es')
      expect(languageSelection.languageChoices[2]).toEqual('fr')
    })

    it('should reorder correctly the languages inside the choices of the language selection step', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('en'),
        actions.addLanguage('es'),
        actions.addLanguage('de'),
        actions.addLanguage('fr'),
        actions.reorderLanguages('en', 4)
      ])

      const languageSelection = state.data.steps[0]
      expect(languageSelection.languageChoices[0]).toEqual('es')
      expect(languageSelection.languageChoices[1]).toEqual('de')
      expect(languageSelection.languageChoices[2]).toEqual('fr')
      expect(languageSelection.languageChoices[3]).toEqual('en')
    })

    it('should reorder correctly the languages inside the choices of the language selection step 2', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('en'),
        actions.addLanguage('es'),
        actions.addLanguage('de'),
        actions.addLanguage('fr'),
        actions.reorderLanguages('fr', 1)
      ])

      const languageSelection = state.data.steps[0]
      expect(languageSelection.languageChoices[0]).toEqual('fr')
      expect(languageSelection.languageChoices[1]).toEqual('en')
      expect(languageSelection.languageChoices[2]).toEqual('es')
      expect(languageSelection.languageChoices[3]).toEqual('de')
    })

    it('should add language', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr')
      ])

      const languages = state.data.languages
      expect(languages).toInclude('fr')
    })

    it('should not add language if it was already added', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.addLanguage('de'),
        actions.addLanguage('fr')
      ])

      const languages = state.data.languages
      expect(languages.reduce((acum, lang) => (lang == 'fr') ? acum + 1 : acum, 0)).toEqual(1)
    })

    it('should remove language', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('de'),
        actions.addLanguage('fr'),
        actions.addLanguage('en')
      ])

      const resultState = playActionsFromState(preState, reducer)([
        actions.removeLanguage('fr')
      ])

      const languages = resultState.data.languages
      expect(languages).toNotInclude('fr')
    })

    it('should remove language and remove language selection step', () => {
      const preState = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire)
      ])

      let oldStepsLength = preState.data.steps.length

      const state = playActionsFromState(preState, reducer)([
        actions.addLanguage('de')
      ])

      const resultState = playActionsFromState(state, reducer)([
        actions.removeLanguage('de')
      ])

      let steps = resultState.data.steps
      expect(steps.length).toEqual(oldStepsLength)
    })

    it('should set default language', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.setDefaultLanguage('fr')
      ])

      expect(state.data.defaultLanguage).toEqual('fr')
    })

    it('should set active language', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.setActiveLanguage('fr')
      ])

      expect(state.data.activeLanguage).toEqual('fr')
    })

    it('should set active language to default language when removing active language', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.setActiveLanguage('fr'),
        actions.removeLanguage('fr')
      ])

      expect(state.data.activeLanguage).toEqual('en')
    })
  })

  it('should autocomplete step prompt sms', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.addLanguage('es'),
      actions.setActiveLanguage('es'),
      actions.changeStepPromptSms('b6588daa-cd81-40b1-8cac-ff2e72a15c15', ''),
      actions.setActiveLanguage('en'),
      actions.autocompleteStepPromptSms('b6588daa-cd81-40b1-8cac-ff2e72a15c15',
        {text: '  New prompt  ', translations: [{language: 'es', text: '  Nuevo prompt  '}, {language: null, text: null}]}
      )]
    )

    const step = find(state.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.prompt['en'].sms).toEqual('New prompt')
    expect(step.prompt['es'].sms).toEqual('Nuevo prompt')
  })

  it('should autocomplete step prompt ivr', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.addLanguage('es'),
      actions.autocompleteStepPromptIvr('b6588daa-cd81-40b1-8cac-ff2e72a15c15',
        {text: '  New prompt  ', translations: [{language: 'es', text: '  Nuevo prompt  '}, {language: null, text: null}]}
      )]
    )

    const step = find(state.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.prompt['en'].ivr.text).toEqual('New prompt')
    expect(step.prompt['es'].ivr.text).toEqual('Nuevo prompt')
  })

  it('should autocomplete msg prompt sms', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.addLanguage('es'),
      actions.autocompleteSmsQuestionnaireMsg('questionnaireMsg',
        {text: '  New prompt  ', translations: [{language: 'es', text: '  Nuevo prompt  '}, {language: null, text: null}]}
      )]
    )

    const prompt = state.data.questionnaireMsg
    expect(prompt['en'].sms).toEqual('New prompt')
    expect(prompt['es'].sms).toEqual('Nuevo prompt')
  })

  it('should autocomplete msg prompt ivr', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.addLanguage('es'),
      actions.autocompleteIvrQuestionnaireMsg('questionnaireMsg',
        {text: '  New prompt  ', translations: [{language: 'es', text: '  Nuevo prompt  '}, {language: null, text: null}]}
      )]
    )

    const prompt = state.data.questionnaireMsg
    expect(prompt['en'].ivr.text).toEqual('New prompt')
    expect(prompt['en'].ivr.audioSource).toEqual('tts')
    expect(prompt['es'].ivr.text).toEqual('Nuevo prompt')
    expect(prompt['es'].ivr.audioSource).toEqual('tts')
  })

  describe('helpers', () => {
    it('should provide valid answers for multiple-choice steps', () => {
      const bareQuestionnaire: Questionnaire = {
        projectId: 1,
        name: 'q1',
        modes: ['sms'],
        languages: [],
        defaultLanguage: 'en',
        activeLanguage: 'en',
        quotaCompletedMsg: {},
        errorMsg: {},
        mobileWebSmsMessage: '',
        mobileWebSurveyIsOverMessage: '',
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
                  'en': {
                    sms: [
                      'Yes'
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
                    ]
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
                }
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
                      'Yes'
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
                      'No'
                    ]
                  }
                },
                skipLogic: null
              }
            ],
            prompt: {
              'en': {
                sms: 'Do you exercise?'
              }
            }
          },
          {
            type: 'multiple-choice',
            title: 'What is your gender?',
            store: 'Gender',
            id: '16588daa-cd81-40b1-8cac-ff2e72a15c15',
            choices: [
              {
                value: 'Male',
                responses: {
                  'en': {
                    sms: [
                      'Male'
                    ]
                  }
                },
                skipLogic: null
              },
              {
                value: 'Female',
                responses: {
                  'en': {
                    sms: [
                      'Female'
                    ]
                  }
                },
                skipLogic: null
              }
            ],
            prompt: {
              'en': {
                sms: 'What is your gender?'
              }
            }
          }
        ],
        id: 1,
        valid: true
      }

      const questionnaire = deepFreeze(bareQuestionnaire)

      expect(stepStoreValues(questionnaire)).toEqual({
        Smokes: {type: 'multiple-choice', values: ['Yes', 'No']},
        Gender: {type: 'multiple-choice', values: ['Male', 'Female']},
        Exercises: {type: 'multiple-choice', values: ['Yes', 'No']}
      })
    })

    it('should provide valid answers for numeric steps', () => {
      const questionnaire = deepFreeze({
        steps: [
          {
            type: 'numeric',
            store: 'Cigarettes'
          },
          {
            type: 'numeric',
            store: 'Exercise'
          }
        ],
        id: 1
      })

      expect(stepStoreValues(questionnaire)).toEqual({
        Cigarettes: {type: 'numeric', values: []},
        Exercise: {type: 'numeric', values: []}
      })
    })

    it('should ignore language-selection steps', () => {
      const questionnaire = deepFreeze({
        steps: [
          {
            type: 'numeric',
            store: 'Cigarettes'
          },
          {
            type: 'multiple-choice',
            store: 'Gender',
            choices: [{value: 'Male'}, {value: 'Female'}]
          },
          {
            type: 'language-selection',
            store: 'Language'
          }
        ],
        id: 1
      })

      expect(stepStoreValues(questionnaire)).toEqual({
        Cigarettes: {type: 'numeric', values: []},
        Gender: {type: 'multiple-choice', values: ['Male', 'Female']}
      })
    })
  })

  describe('quotas', () => {
    it('should set quota_completed_msg for the first time', () => {
      const smsText = '  Thanks for participating in the poll  '
      const ivrText = {text: '  Thank you very much  ', audioSource: 'tts'}

      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', smsText),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', ivrText)
      ])

      expect(state.data.quotaCompletedMsg['en']['sms']).toEqual(smsText.trim())
      expect(state.data.quotaCompletedMsg['en']['ivr']).toEqual({text: 'Thank you very much', audioSource: 'tts'})
    })

    it('should set quota_completed_msg for mobile web', () => {
      const mobilewebText = 'Thanks for participating in the poll'

      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setMobileWebQuestionnaireMsg('quotaCompletedMsg', mobilewebText)
      ])

      expect(state.data.quotaCompletedMsg['en']['mobileweb']).toEqual(mobilewebText)
    })

    it('should set mobile web sms message', () => {
      const mobileWebSmsMessage = 'Click here'

      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setMobileWebSmsMessage(mobileWebSmsMessage)
      ])

      expect(state.data.mobileWebSmsMessage).toEqual(mobileWebSmsMessage)
    })

    it('should set mobile web survey is over message', () => {
      const mobileWebSurveyIsOverMessage = 'Done'

      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.setMobileWebSurveyIsOverMessage(mobileWebSurveyIsOverMessage)
      ])

      expect(state.data.mobileWebSurveyIsOverMessage).toEqual(mobileWebSurveyIsOverMessage)
    })

    it('should not modify other mode quota message', () => {
      const quotaMessage = {
        'en': {
          'sms': 'thanks for answering sms',
          'ivr': { audioSource: 'tts', text: 'thanks for answering phone call' }
        }
      }

      let q = Object.assign({}, questionnaire)
      q.quotaCompletedMsg = quotaMessage

      const newIvrText = {text: 'Thank you very much', audioSource: 'tts'}

      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(q),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', newIvrText)
      ])

      expect(state.data.quotaCompletedMsg['en']['sms']).toEqual('thanks for answering sms')
      expect(state.data.quotaCompletedMsg['en']['ivr']).toEqual(newIvrText)
    })
  })

  describe('csv for translation', () => {
    it('should work', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.addLanguage('es'),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', 'Done'),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', {text: 'Done!', audioSource: 'tts'})
      ])

      const csv = csvForTranslation(state.data)

      const expected = [
        ['English', 'French', 'Spanish'],
        ['Do you smoke?', '', 'Fumas?'],
        ['Do you really smoke?', '', ''],
        ['Yes, Y, 1', '', 'Sí, S, 1'],
        ['Of course', '', 'Por supuesto'],
        ['No, N, 2', '', 'No, N, 2'],
        ['Not at all', '', 'Para nada'],
        ['Do you exercise?', '', 'Ejercitas?'],
        ['Done', '', ''],
        ['Done!', '', '']
      ]

      expect(csv.length).toEqual(expected.length)
      expected.forEach((row, index) => expect(csv[index]).toEqual(row))
    })

    it('should not duplicate sms and ivr quota completed msg (#421)', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('fr'),
        actions.addLanguage('es'),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', 'Done'),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', {text: 'Done', audioSource: 'tts'})
      ])

      const csv = csvForTranslation(state.data)

      const expected = [
        ['English', 'French', 'Spanish'],
        ['Do you smoke?', '', 'Fumas?'],
        ['Do you really smoke?', '', ''],
        ['Yes, Y, 1', '', 'Sí, S, 1'],
        ['Of course', '', 'Por supuesto'],
        ['No, N, 2', '', 'No, N, 2'],
        ['Not at all', '', 'Para nada'],
        ['Do you exercise?', '', 'Ejercitas?'],
        ['Done', '', '']
      ]

      expect(csv.length).toEqual(expected.length)
      expected.forEach((row, index) => expect(csv[index]).toEqual(row))
    })

    it('should upload csv', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.uploadCsvForTranslation(
          [
            ['  English  ', '  Spanish  '],
            ['  Do you smoke?  ', '  Cxu vi fumas?  '],
            ['  Do you exercise?  ', '  Cxu vi ekzercas?  '],
            ['  Yes, Y, 1  ', '  Jes, J, 1  ']
          ]
        )
      ])

      expect(state.data.steps[1].prompt.es.sms).toEqual('Cxu vi fumas?')
      expect(state.data.steps[2].prompt.es.sms).toEqual('Cxu vi ekzercas?')

      expect(state.data.steps[1].choices[0].responses.sms.es).toEqual(['Jes', 'J', '1'])
      expect(state.data.steps[1].choices[1].responses.sms.es).toEqual(['No', 'N', '2']) // original preserved

      expect(state.data.steps[1].prompt.es.ivr.text).toEqual('Cxu vi fumas?')
    })

    it('should upload csv with quota completed msg', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.setSmsQuestionnaireMsg('quotaCompletedMsg', 'Done'),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', {text: 'Done!', audioSource: 'tts'}),
        actions.uploadCsvForTranslation(
          [
            ['English', 'Spanish'],
            ['Do you smoke?', 'Cxu vi fumas?'],
            ['Do you exercise?', 'Cxu vi ekzercas?'],
            ['Yes, Y, 1', 'Jes, J, 1'],
            ['Done', 'Listo'],
            ['Done!', 'Listo!']
          ]
        )
      ])

      expect(state.data.quotaCompletedMsg.es.sms).toEqual('Listo')
      expect(state.data.quotaCompletedMsg.es.ivr).toEqual({text: 'Listo!', audioSource: 'tts'})
    })

    it('should upload csv with quota completed msg that lacks audioSource', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addLanguage('es'),
        actions.setIvrQuestionnaireMsg('quotaCompletedMsg', {text: 'Done!', audioSource: 'tts'}),
        actions.uploadCsvForTranslation(
          [
            ['English', 'Spanish'],
            ['Done!', 'Listo!']
          ]
        )
      ])

      expect(state.data.quotaCompletedMsg.es.ivr).toEqual({text: 'Listo!', audioSource: 'tts'})
    })

    it('should compute a valid alphanumeric filename', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.changeName('Foo!@#%!     123  []]!!!??')
      ])
      expect(csvTranslationFilename((state.data: Questionnaire))).toEqual('Foo123_translations.csv')
    })

    it('changes numeric limits without min and max', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addStep()
      ])

      const stepId = state.data.steps[state.data.steps.length - 1].id

      const resultState = playActionsFromState(state, reducer)([
        actions.changeStepType(stepId, 'numeric'),
        actions.changeNumericRanges(stepId, '', '', '1,3,5')
      ])

      const step = resultState.data.steps[resultState.data.steps.length - 1]
      const expected = [
        { from: null, to: 0, skipLogic: null },
        { from: 1, to: 2, skipLogic: null },
        { from: 3, to: 4, skipLogic: null },
        { from: 5, to: null, skipLogic: null }
      ]

      expect(isEqual(step.ranges, expected)).toEqual(true)
    })

    it('changes numeric limits without min and max, with zero in delimiter', () => {
      const state = playActions([
        actions.fetch(1, 1),
        actions.receive(questionnaire),
        actions.addStep()
      ])

      const stepId = state.data.steps[state.data.steps.length - 1].id

      const resultState = playActionsFromState(state, reducer)([
        actions.changeStepType(stepId, 'numeric'),
        actions.changeNumericRanges(stepId, '', '', '0,3,5')
      ])

      const step = resultState.data.steps[resultState.data.steps.length - 1]
      const expected = [
        { from: null, to: -1, skipLogic: null },
        { from: 0, to: 2, skipLogic: null },
        { from: 3, to: 4, skipLogic: null },
        { from: 5, to: null, skipLogic: null }
      ]

      expect(isEqual(step.ranges, expected)).toEqual(true)
    })
  })
})
