export const UPLOAD_AUDIO = 'UPLOAD_AUDIO'
export const FINISH_AUDIO_UPLOAD = 'FINISH_AUDIO_UPLOAD'
export const IMPORT_QUESTIONNAIRE = 'IMPORT_QUESTIONNAIRE'
export const UPDATE_IMPORT_PERCENTAGE = 'UPDATE_IMPORT_PERCENTAGE'
export const FINISH_QUESTIONNAIRE_IMPORT = 'FINISH_QUESTIONNAIRE_IMPORT'
export const SURVEY_COMPARISON_SELECT_PRIMARY = 'SURVEY_COMPARISON_SELECT_PRIMARY'
export const SURVEY_COMPARISON_SELECT_FALLBACK = 'SURVEY_COMPARISON_SELECT_FALLBACK'
export const SURVEY_ADD_COMPARISON_MODE = 'SURVEY_ADD_COMPARISON_MODE'
export const SURVEY_TOGGLE_BLOCKED_DAYS = 'SURVEY_TOGGLE_BLOCKED_DAYS'
export const QUESTIONNAIRE_DESELECT_STEP = 'QUESTIONNAIRE_DESELECT_STEP'
export const QUESTIONNAIRE_SELECT_STEP = 'QUESTIONNAIRE_SELECT_STEP'
export const QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP = 'QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP'
export const QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP = 'QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP'

export const uploadAudio = (stepId) => ({
  type: UPLOAD_AUDIO,
  stepId
})

export const finishAudioUpload = (stepId) => ({
  type: FINISH_AUDIO_UPLOAD,
  stepId
})

export const importQuestionnaire = () => ({
  type: IMPORT_QUESTIONNAIRE
})

export const updateImportPercentage = (importPercentage) => ({
  type: UPDATE_IMPORT_PERCENTAGE,
  importPercentage
})

export const finishQuestionnaireImport = () => ({
  type: FINISH_QUESTIONNAIRE_IMPORT
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
