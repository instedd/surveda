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
          uploadingAudio: null
        },
        surveyWizard: {
          primaryModeSelected: null,
          fallbackModeSelected: null
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
  })
})
