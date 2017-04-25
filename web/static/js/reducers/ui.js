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
      surveyWizard: {
        ...state.data.surveyWizard,
        fallbackModeSelected: action.mode
      }
    }
  }
}
