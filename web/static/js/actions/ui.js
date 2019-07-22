import * as api from '../api'
import * as questionnaireActions from './questionnaire'
import { cancel } from '../uploadManager'

export const UPLOAD_AUDIO = 'UPLOAD_AUDIO'
export const FINISH_AUDIO_UPLOAD = 'FINISH_AUDIO_UPLOAD'
export const UPLOAD_STARTED = 'QUESTIONNAIRE_UPLOAD_STARTED'
export const UPLOAD_FINISHED = 'QUESTIONNAIRE_UPLOAD_FINISHED'
export const UPLOAD_PROGRESS = 'QUESTIONNAIRE_UPLOAD_PROGRESS'
export const UPLOAD_ERRORED = 'QUESTIONNAIRE_UPLOAD_ERRORED'
export const SURVEY_COMPARISON_SELECT_PRIMARY = 'SURVEY_COMPARISON_SELECT_PRIMARY'
export const SURVEY_COMPARISON_SELECT_FALLBACK = 'SURVEY_COMPARISON_SELECT_FALLBACK'
export const SURVEY_ADD_COMPARISON_MODE = 'SURVEY_ADD_COMPARISON_MODE'
export const SURVEY_TOGGLE_BLOCKED_DAYS = 'SURVEY_TOGGLE_BLOCKED_DAYS'
export const QUESTIONNAIRE_DESELECT_STEP = 'QUESTIONNAIRE_DESELECT_STEP'
export const QUESTIONNAIRE_SELECT_STEP = 'QUESTIONNAIRE_SELECT_STEP'
export const QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP = 'QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP'
export const QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP = 'QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP'
export const SURVEY_SET_CUTOFF_CONFIG = 'SURVEY_SET_CUTOFF_CONFIG'
export const SET_INITIAL_CUTOFF_CONFIG = 'SET_INITIAL_CUTOFF_CONFIG'
export const SURVEY_CUTOFF_CONFIG_VALID = 'SURVEY_CUTOFF_CONFIG_VALID'

export const surveyCutOffConfigValid = (config: string, nextValue) => ({
  type: SURVEY_CUTOFF_CONFIG_VALID,
  config,
  nextValue
})

export const surveySetCutOffConfig = (config: string) => ({
  type: SURVEY_SET_CUTOFF_CONFIG,
  config
})

export const setInitialCutOffConfig = (survey) => ({
  type: SET_INITIAL_CUTOFF_CONFIG,
  survey
})

export const uploadAudio = (stepId) => ({
  type: UPLOAD_AUDIO,
  stepId
})

export const finishAudioUpload = (stepId) => ({
  type: FINISH_AUDIO_UPLOAD,
  stepId
})

export const importQuestionnaire = (projectId, questionnaireId, file) => (dispatch, getState) => {
  const onProgress = (total, loaded) => {
    dispatch(uploadProgress(total, loaded))
  }

  const onCompleted = (questionnaire) => {
    dispatch(deselectStep())
    dispatch(deselectQuotaCompletedStep())
    dispatch(questionnaireActions.receive(questionnaire))
    dispatch(questionnaireActions.setDirty())
    dispatch(uploadFinished())
  }

  const onError = (description) => {
    dispatch(uploadErrored(description))
  }

  const onAbort = () => {
    dispatch(uploadFinished())
  }

  const uploadId = api.importQuestionnaireZip(projectId, questionnaireId, file, onCompleted, onProgress, onAbort, onError)

  dispatch(uploadStarted(uploadId))
}

export const uploadStarted = (uploadId) => ({
  type: UPLOAD_STARTED,
  uploadId
})

export const uploadProgress = (total, loaded) => ({
  type: UPLOAD_PROGRESS,
  total,
  loaded
})

export const uploadFinished = () => ({
  type: UPLOAD_FINISHED
})

export const uploadCancelled = (uploadId) => {
  cancel(uploadId)
}

export const uploadErrored = (description) => ({
  type: UPLOAD_ERRORED,
  description
})

export const comparisonPrimarySelected = (mode: string) => ({
  type: SURVEY_COMPARISON_SELECT_PRIMARY,
  mode
})

export const comparisonFallbackSelected = (mode: string) => ({
  type: SURVEY_COMPARISON_SELECT_FALLBACK,
  mode
})

export const addModeComparison = () => ({
  type: SURVEY_ADD_COMPARISON_MODE
})

export const toggleBlockedDays = () => ({
  type: SURVEY_TOGGLE_BLOCKED_DAYS
})

export const deselectStep = () => ({
  type: QUESTIONNAIRE_DESELECT_STEP
})

export const selectStep = (stepId, isNew) => ({
  type: QUESTIONNAIRE_SELECT_STEP,
  stepId,
  isNew
})

export const deselectQuotaCompletedStep = () => ({
  type: QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP
})

export const selectQuotaCompletedStep = (stepId, isNew) => ({
  type: QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP,
  stepId,
  isNew
})
