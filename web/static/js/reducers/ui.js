import * as actions from '../actions/ui'

const initialState = {
  data: {
    questionnaireEditor: {
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
      fallbackModeSelected: null
    }
  },
  errors: {}
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.UPLOAD_AUDIO: return uploadingAudio(state, action)
    case actions.FINISH_AUDIO_UPLOAD: return finishAudioUpload(state, action)
    case actions.SURVEY_COMPARISON_SELECT_PRIMARY: return selectPrimaryComparison(state, action)
    case actions.SURVEY_COMPARISON_SELECT_FALLBACK: return selectFallbackComparison(state, action)
    case actions.SURVEY_ADD_COMPARISON_MODE: return resetMode(state, action)
    case actions.QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP: return selectQuotaCompletedStep(state, action)
    case actions.QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP: return deselectQuotaCompletedStep(state, action)
    case actions.QUESTIONNAIRE_SELECT_STEP: return selectStep(state, action)
    case actions.QUESTIONNAIRE_DESELECT_STEP: return deselectStep(state, action)
    default: return state
  }
}

const uploadingAudio = (state, action) => {
  return {
    ...state,
    data: {
      questionnaireEditor: {
        uploadingAudio: action.stepId
      }
    }
  }
}

const finishAudioUpload = (state, action) => {
  return {
    ...state,
    data: {
      questionnaireEditor: {
        uploadingAudio: null
      }
    }
  }
}

const selectPrimaryComparison = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      surveyWizard: {
        ...state.data.surveyWizard,
        primaryModeSelected: action.mode
      }
    }
  }
}

const selectFallbackComparison = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      surveyWizard: {
        ...state.data.surveyWizard,
        fallbackModeSelected: action.mode
      }
    }
  }
}

const resetMode = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      surveyWizard: {
        ...state.data.surveyWizard,
        primaryModeSelected: null,
        fallbackModeSelected: null
      }
    }
  }
}

const selectStep = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      questionnaireEditor: {
        ...state.data.questionnaireEditor,
        steps: {
          currentStepId: action.stepId,
          currentStepIsNew: action.isNew
        }
      }
    }
  }
}

const selectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      questionnaireEditor: {
        ...state.data.questionnaireEditor,
        quotaCompletedSteps: {
          currentStepId: action.stepId,
          currentStepIsNew: action.isNew
        }
      }
    }
  }
}

const deselectStep = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      questionnaireEditor: {
        ...state.data.questionnaireEditor,
        steps: {
          currentStepId: null,
          currentStepIsNew: false
        }
      }
    }
  }
}

const deselectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      questionnaireEditor: {
        ...state.data.questionnaireEditor,
        quotaCompletedSteps: {
          currentStepId: null,
          currentStepIsNew: false
        }
      }
    }
  }
}
