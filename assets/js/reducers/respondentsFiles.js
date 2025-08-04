import * as actions from "../actions/survey"

export default (state = {}, action) => {
  switch (action.type) {
    case actions.GENERATING_FILE:
      return {
        ...state,
        files: {
          ...(state.files || {}),
          [action.file]: {
            ...(state.files || {})[action.file],
            file_type: action.file,
            creating: true,
            created_at: null
          }
        }
      }
    case actions.FETCHING_FILES_STATUS:
      if (action.surveyId != state.surveyId) {
        return {
          ...state,
          surveyId: null,
          surveyState: null,
          files: null,
        }
      } else {
        return state
      }
    case actions.RECEIVE_FILES_STATUS:
      return {
        ...state,
        surveyId: action.surveyId,
        surveyState: action.surveyState,
        files: action.files,
      }
    default:
      return state
  }
}
