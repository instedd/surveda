import * as actions from '../actions/ui'
// import fetchReducer from './fetch'
// import drop from 'lodash/drop'
// import flatten from 'lodash/flatten'
// import map from 'lodash/map'
// import split from 'lodash/split'
// import find from 'lodash/find'
// import findIndex from 'lodash/findIndex'
// import isEqual from 'lodash/isEqual'
// import uniqWith from 'lodash/uniqWith'
// import every from 'lodash/every'
// import some from 'lodash/some'

const initialState = {
  data: {
    questionnaireEditor: {
      uploadingAudio: null
    }
  },
  errors: {}
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.UPLOAD_AUDIO: return uploadingAudio(state, action)
    case actions.FINISH_AUDIO_UPLOAD: return finishAudioUpload(state, action)
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
