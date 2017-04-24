export const UPLOAD_AUDIO = 'UPLOAD_AUDIO'
export const FINISH_AUDIO_UPLOAD = 'FINISH_AUDIO_UPLOAD'
export const SURVEY_COMPARISON_SELECT_PRIMARY = 'SURVEY_COMPARISON_SELECT_PRIMARY'
export const SURVEY_COMPARISON_SELECT_FALLBACK = 'SURVEY_COMPARISON_SELECT_FALLBACK'

export const uploadAudio = (stepId) => ({
  type: UPLOAD_AUDIO,
  stepId
})

export const finishAudioUpload = (stepId) => ({
  type: FINISH_AUDIO_UPLOAD,
  stepId
})

export const comparisonPrimarySelected = (mode: string) => ({
  type: SURVEY_COMPARISON_SELECT_PRIMARY,
  mode
})

export const comparisonFallbackSelected = (mode: string) => ({
  type: SURVEY_COMPARISON_SELECT_FALLBACK,
  mode
})
