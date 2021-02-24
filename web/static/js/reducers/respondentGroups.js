import * as actions from '../actions/respondentGroups'

const initialState = {
  fetching: false,
  uploading: false,
  uploadingExisting: {},
  items: null,
  surveyId: null,
  invalidRespondents: null,
  invalidRespondentsForGroup: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_RESPONDENT_GROUPS: return fetchRespondentGroups(state, action)
    case actions.UPLOAD_RESPONDENT_GROUP: return uploadRespondentGroup(state, action)
    case actions.UPLOAD_EXISTING_RESPONDENT_GROUP_ID: return uploadExistingRespondentGroup(state, action)
    case actions.DONE_UPLOAD_EXISTING_RESPONDENT_GROUP_ID: return doneUploadExistingRespondentGroup(state, action)
    case actions.RECEIVE_RESPONDENT_GROUPS: return receiveRespondentGroups(state, action)
    case actions.RECEIVE_RESPONDENT_GROUP: return receiveRespondentGroup(state, action)
    case actions.REMOVE_RESPONDENT_GROUP: return removeRespondentGroup(state, action)
    case actions.INVALID_RESPONDENTS: return receiveInvalids(state, action)
    case actions.CLEAR_INVALIDS: return clearInvalids(state, action)
    case actions.INVALID_RESPONDENTS_FOR_GROUP: return receiveInvalidsForGroup(state, action)
    case actions.CLEAR_INVALID_RESPONDENTS_FOR_GROUP: return clearInvalidsForGroup(state, action)
    case actions.SELECT_CHANNELS: return selectChannels(state, action)
    default: return state
  }
}

const fetchRespondentGroups = (state, action) => {
  const items = state.surveyId == action.surveyId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    surveyId: action.surveyId,
    invalidRespondents: null
  }
}

const uploadRespondentGroup = (state, action) => {
  return {
    ...state,
    uploading: true
  }
}

const uploadExistingRespondentGroup = (state, action) => {
  return {
    ...state,
    uploadingExisting: {
      ...state.uploadingExisting,
      [action.id]: true
    }
  }
}

const doneUploadExistingRespondentGroup = (state, action) => {
  return {
    ...state,
    uploadingExisting: {
      ...state.uploadingExisting,
      [action.id]: false
    }
  }
}

const receiveRespondentGroups = (state, action) => {
  if (state.surveyId != action.surveyId) {
    return state
  }

  const respondentGroups = action.respondentGroups
  return {
    ...state,
    fetching: false,
    uploading: false,
    items: respondentGroups,
    invalidRespondents: null
  }
}

const receiveRespondentGroup = (state, action) => {
  const group = action.respondentGroup
  return {
    ...state,
    fetching: false,
    uploading: false,
    items: {
      ...state.items,
      [group.id]: group
    }
  }
}

const removeRespondentGroup = (state, action) => {
  const items = {...state.items}
  delete items[action.id]

  return {
    ...state,
    fetching: false,
    items
  }
}

const receiveInvalids = (state, action) => ({
  ...state,
  invalidRespondents: action.invalidRespondents
})

const clearInvalids = (state, action) => {
  return {
    ...state,
    invalidRespondents: null,
    uploading: false
  }
}

const receiveInvalidsForGroup = (state, action) => {
  const first = action.invalidRespondents.invalidEntries[0]
  return {
    ...state,
    invalidRespondentsForGroup: {type: first.type, lineNumber: first.line_number}
  }
}

const clearInvalidsForGroup = (state, action) => ({
  ...state,
  invalidRespondentsForGroup: null
})

const selectChannels = (state, action) => {
  return {
    ...state,
    items: {
      ...state.items,
      [action.groupId]: {
        ...state.items[action.groupId],
        channels: action.channels
      }
    }
  }
}
