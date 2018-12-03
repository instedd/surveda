/* eslint-env mocha */
import expect from 'expect'
import assert from 'assert'
import reducer from '../../../web/static/js/reducers/ui'
import { playActionsFromState } from '../spec_helper'
import * as actions from '../../../web/static/js/actions/ui'

describe('ui reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({
      data: {
        questionnaireEditor: {
          importPercentage: 0,
          importingQuestionnaire: false,
          uploadingAudio: null,
          steps: {
            currentStepId: null,
            currentStepIsNew: false
          },
          quotaCompletedSteps: {
            currentStepId: null,
            currentStepIsNew: false
          }
        },
        surveyWizard: {
          primaryModeSelected: null,
          fallbackModeSelected: null,
          allowBlockedDays: false
        }
      },
      errors: {}
    })
  })

  it('should set uploadingAudio', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([actions.uploadAudio('17141bea-a81c-4227-bdda-f5f69188b0e7')])
    expect(result.data.questionnaireEditor.uploadingAudio).toEqual('17141bea-a81c-4227-bdda-f5f69188b0e7')
  })

  it('shoud finish audio upload', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([
      actions.uploadAudio('17141bea-a81c-4227-bdda-f5f69188b0e7'),
      actions.finishAudioUpload()
    ])
    assert(!result.data.questionnaireEditor.uploadingAudio)
  })

  it('should start importing questionnaire', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([
      actions.importQuestionnaire()
    ])
    assert(result.data.questionnaireEditor.importingQuestionnaire)
  })

  it('should update import percentage', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([
      actions.updateImportPercentage(50)
    ])
    expect(result.data.questionnaireEditor.importPercentage).toEqual(50)
  })

  describe('survey modes', () => {
    it('should select primary mode', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([actions.comparisonPrimarySelected('mobileweb')])
      expect(result.data.surveyWizard.primaryModeSelected).toEqual('mobileweb')
    })

    it('should select fallback mode', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.comparisonPrimarySelected('mobileweb'),
        actions.comparisonFallbackSelected('sms')
      ])
      expect(result.data.surveyWizard.primaryModeSelected).toEqual('mobileweb')
      expect(result.data.surveyWizard.fallbackModeSelected).toEqual('sms')
    })

    it('should reset primary and fallback modes', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.comparisonPrimarySelected('mobileweb'),
        actions.comparisonFallbackSelected('sms'),
        actions.addModeComparison()
      ])
      assert(!result.data.surveyWizard.primaryModeSelected)
      assert(!result.data.surveyWizard.fallbackModeSelected)
    })

    it('should keep questionnaireEditor state', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.uploadAudio('17141bea-a81c-4227-bdda-f5f69188b0e7'),
        actions.comparisonPrimarySelected('mobileweb'),
        actions.comparisonFallbackSelected('sms'),
        actions.addModeComparison()
      ])
      expect(result.data.questionnaireEditor.uploadingAudio).toEqual('17141bea-a81c-4227-bdda-f5f69188b0e7')
    })
  })
})
