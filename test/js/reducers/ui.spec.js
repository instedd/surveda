/* eslint-env mocha */
import expect from 'expect'
import assert from 'assert'
import reducer from '../../../assets/js/reducers/ui'
import { playActionsFromState } from '../spec_helper'
import * as actions from '../../../assets/js/actions/ui'
import { survey } from '../fixtures'

describe('ui reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({
      data: {
        questionnaireEditor: {
          uploadingAudio: null,
          upload: {
            uploadId: null,
            progress: 0,
            error: null
          },
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
          allowBlockedDays: false,
          cutOffConfig: 'default'
        }
      }
    })
  })

  it('should set initialCutOffConfig for survey', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([actions.setInitialCutOffConfig(survey)])
    expect(result.data.surveyWizard.cutOffConfig).toEqual('cutoff')
    expect(result.data.surveyWizard.cutOffConfigValid).toEqual(true)
  })

  it('should set cutOffConfigValid for survey', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([actions.surveyCutOffConfigValid('cutoff', survey.cutoff)])
    expect(result.data.surveyWizard.cutOffConfigValid).toEqual(true)
  })

  it('should set cutOffConfig for default option', () => {
    const playActions = playActionsFromState(initialState, reducer)
    const result = playActions([actions.surveySetCutOffConfig('default')])
    expect(result.data.surveyWizard.cutOffConfig).toEqual('default')
    expect(result.data.surveyWizard.cutOffConfigValid).toEqual(true)
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

  describe('uploading questionnaire', () => {
    it('should start upload', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.uploadStarted(4)
      ])
      expect(result.data.questionnaireEditor.upload.uploadId).toEqual(4)
    })

    it('should update progress', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.uploadProgress(50000, 25000)
      ])
      expect(result.data.questionnaireEditor.upload.progress).toEqual(50)
    })

    it('should finish upload', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.uploadStarted(4),
        actions.uploadProgress(50000, 25000),
        actions.uploadFinished()
      ])
      expect(result.data.questionnaireEditor.upload.uploadId).toEqual(null)
      expect(result.data.questionnaireEditor.upload.progress).toEqual(0)
      expect(result.data.questionnaireEditor.upload.error).toEqual(null)
    })

    it('should add error', () => {
      const playActions = playActionsFromState(initialState, reducer)
      const result = playActions([
        actions.uploadStarted(4),
        actions.uploadProgress(50000, 25000),
        actions.uploadErrored('Timeout')
      ])
      expect(result.data.questionnaireEditor.upload.uploadId).toEqual(4)
      expect(result.data.questionnaireEditor.upload.progress).toEqual(50)
      expect(result.data.questionnaireEditor.upload.error).toEqual('Timeout')
    })
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
