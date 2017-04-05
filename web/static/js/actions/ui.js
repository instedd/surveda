export const UPLOAD_AUDIO = 'UPLOAD_AUDIO'
export const FINISH_AUDIO_UPLOAD = 'FINISH_AUDIO_UPLOAD'

export const uploadAudio = (stepId) => ({
  type: UPLOAD_AUDIO,
  stepId
})

export const finishAudioUpload = (stepId) => ({
  type: FINISH_AUDIO_UPLOAD,
  stepId
})
