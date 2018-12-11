import * as actions from '../../actions/ui'

const initialState = {
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
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.UPLOAD_AUDIO: return uploadingAudio(state, action)
    case actions.FINISH_AUDIO_UPLOAD: return finishAudioUpload(state, action)
    case actions.UPLOAD_STARTED: return uploadStarted(state, action)
    case actions.UPLOAD_PROGRESS: return uploadProgress(state, action)
    case actions.UPLOAD_FINISHED: return uploadFinished(state, action)
    case actions.UPLOAD_ERRORED: return uploadErrored(state, action)
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
    uploadingAudio: action.stepId
  }
}

const finishAudioUpload = (state, action) => {
  return {
    ...state,
    uploadingAudio: null
  }
}

const uploadStarted = (state, action) => {
  return {
    ...state,
    upload: {
      ...state.upload,
      uploadId: action.uploadId
    }
  }
}

const uploadProgress = (state, action) => {
  return {
    ...state,
    upload: {
      ...state.upload,
      progress: Math.floor(action.loaded / action.total * 100)
    }
  }
}

const uploadFinished = (state, action) => {
  return {
    ...state,
    upload: {
      ...state.upload,
      uploadId: null,
      progress: 0,
      error: null
    }
  }
}

const uploadErrored = (state, action) => {
  return {
    ...state,
    upload: {
      ...state.upload,
      error: action.description
    }
  }
}

const selectStep = (state, action) => {
  return {
    ...state,
    steps: {
      currentStepId: action.stepId,
      currentStepIsNew: action.isNew
    }
  }
}

const selectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    quotaCompletedSteps: {
      currentStepId: action.stepId,
      currentStepIsNew: action.isNew
    }
  }
}

const deselectStep = (state, action) => {
  return {
    ...state,
    steps: {
      currentStepId: null,
      currentStepIsNew: false
    }
  }
}

const deselectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    quotaCompletedSteps: {
      currentStepId: null,
      currentStepIsNew: false
    }
  }
}
