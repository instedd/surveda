import * as api from '../api'
import * as surveyActions from './survey'

export const RECEIVE_RESPONDENT_GROUPS = 'RESPONDENT_GROUPS_RECEIVE'
export const RECEIVE_RESPONDENT_GROUP = 'RESPONDENT_GROUP_RECEIVE'
export const REMOVE_RESPONDENT_GROUP = 'RESPONDENT_GROUP_REMOVE'
export const FETCH_RESPONDENT_GROUPS = 'RESPONDENT_GROUPS_FETCH'
export const INVALID_RESPONDENTS = 'RESPONDENT_GROUP_INVALID_RESPONDENTS'
export const INVALID_RESPONDENTS_FOR_GROUP = 'RESPONDENT_GROUP_INVALID_RESPONDENTS_FOR_GROUP'
export const CLEAR_INVALID_RESPONDENTS_FOR_GROUP = 'RESPONDENT_GROUP_CLEAR_INVALID_RESPONDENTS_FOR_GROUP'
export const CLEAR_INVALIDS = 'RESPONDENT_GROUP_CLEAR_INVALIDS'
export const SELECT_CHANNELS = 'RESPONDENT_GROUP_SELECT_CHANNELS'
export const UPLOAD_RESPONDENT_GROUP = 'RESPONDENT_GROUP_UPLOAD'
export const UPLOAD_EXISTING_RESPONDENT_GROUP_ID = 'RESPONDENT_GROUP_UPLOAD_EXISTING'
export const DONE_UPLOAD_EXISTING_RESPONDENT_GROUP_ID = 'RESPONDENT_GROUP_DONE_UPLOAD_EXISTING'

export const fetchRespondentGroups = (projectId, surveyId) => dispatch => {
  dispatch(startFetchingRespondentGroups(surveyId))
  api.fetchRespondentGroups(projectId, surveyId)
    .then(response => {
      dispatch(receiveRespondentGroups(surveyId, response.entities.respondentGroups))
    })
}

export const startFetchingRespondentGroups = (surveyId) => ({
  type: FETCH_RESPONDENT_GROUPS,
  surveyId
})

export const receiveRespondentGroups = (surveyId, respondentGroups) => ({
  type: RECEIVE_RESPONDENT_GROUPS,
  surveyId,
  respondentGroups
})

export const receiveRespondentGroup = (respondentGroup) => ({
  type: RECEIVE_RESPONDENT_GROUP,
  respondentGroup
})

export const receiveInvalids = (invalidRespondents) => ({
  type: INVALID_RESPONDENTS,
  invalidRespondents: invalidRespondents
})

export const receiveInvalidsForGroup = (groupId, invalidRespondents) => ({
  type: INVALID_RESPONDENTS_FOR_GROUP,
  groupId,
  invalidRespondents
})

export const clearInvalids = () => ({
  type: CLEAR_INVALIDS
})

export const clearInvalidsRespondentsForGroup = () => ({
  type: CLEAR_INVALID_RESPONDENTS_FOR_GROUP
})

export const uploadRespondentGroup = (projectId, surveyId, files) => (dispatch, getState) => {
  dispatch(uploadingRespondentGroup())
  handleRespondentGroupUpload(dispatch,
    api.uploadRespondentGroup(projectId, surveyId, files)
  )
}

export const addMoreRespondentsToGroup = (projectId, surveyId, groupId, file) => (dispatch, getState) => {
  dispatch(uploadingExistingRespondentGroup(groupId))
  handleRespondentGroupUpload(dispatch,
    api.addMoreRespondentsToGroup(projectId, surveyId, groupId, file),
    groupId
  )
}

export const replaceRespondents = (projectId, surveyId, groupId, file) => (dispatch, getState) => {
  dispatch(uploadingExistingRespondentGroup(groupId))
  handleRespondentGroupUpload(dispatch,
    api.replaceRespondents(projectId, surveyId, groupId, file),
    groupId
  )
}

// Until now, no call to handleRespondentGroupUpload (uploadRespondentGroup,
// addMoreREspondentsToGroup and replaceRespondents) requires a
// surveyActions.save().
// In order to fix #1429, the explicit call to surveyActions.save() was removed
// from handleRespondentGroupUpload, as it was suggested in a previous comment

const handleRespondentGroupUpload = (dispatch, promise, groupId = null) => {
  promise.then(response => {
    const group = response.entities.respondentGroups[response.result]
    if (groupId) dispatch(doneUploadingExistingRespondentGroup(groupId))
    dispatch(receiveRespondentGroup(group))
  }, (e) => {
    if (groupId) dispatch(doneUploadingExistingRespondentGroup(groupId))
    e.json().then((value) => {
      if (groupId) {
        dispatch(receiveInvalidsForGroup(groupId, value))
      } else {
        dispatch(receiveInvalids(value))
      }
    })
  })
}

export const uploadingRespondentGroup = () => ({
  type: UPLOAD_RESPONDENT_GROUP
})

export const uploadingExistingRespondentGroup = (id) => ({
  type: UPLOAD_EXISTING_RESPONDENT_GROUP_ID,
  id
})

export const doneUploadingExistingRespondentGroup = (id) => ({
  type: DONE_UPLOAD_EXISTING_RESPONDENT_GROUP_ID,
  id
})

export const removeRespondentGroup = (projectId, surveyId, groupId) => (dispatch, getState) => {
  api.removeRespondentGroup(projectId, surveyId, groupId)
  .then(() => dispatch(surveyActions.save()))

  dispatch({
    type: REMOVE_RESPONDENT_GROUP,
    id: groupId
  })
}

export const selectChannels = (projectId, surveyId, groupId, channels) => (dispatch, getState) => {
  api.updateRespondentGroup(projectId, surveyId, groupId, { channels })
  .then(() => dispatch(surveyActions.save()))

  dispatch({
    type: SELECT_CHANNELS,
    groupId,
    channels
  })
}
