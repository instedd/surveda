import * as actions from "../actions/survey"

const markAsCreating = (files, creatingFile) => ({
  ...files,
  [creatingFile]: {
    ...files[creatingFile],
    file_type: creatingFile,
    creating: true,
    created_at: null,
  }
})

export default (state = {}, action) => {
  switch (action.type) {
    case actions.GENERATING_FILE:
      return {
        ...state,
        files: markAsCreating(state.files || {}, action.file),
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
