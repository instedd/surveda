import * as api from '../api'
import * as surveyActions from './survey'

export const RECEIVE_RESPONDENT_GROUPS = 'RESPONDENT_GROUPS_RECEIVE'
export const RECEIVE_RESPONDENT_GROUP = 'RESPONDENT_GROUP_RECEIVE'
export const REMOVE_RESPONDENT_GROUP = 'RESPONDENT_GROUP_REMOVE'
export const FETCH_RESPONDENT_GROUPS = 'RESPONDENT_GROUPS_FETCH'
export const INVALID_RESPONDENT_GROUPS = 'RESPONDENT_GROUP_INVALID_GROUPS'
export const INVALID_RESPONDENTS = 'RESPONDENT_GROUP_INVALID_RESPONDENTS'
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

export const clearInvalids = () => ({
  type: CLEAR_INVALIDS
})

// TODO (ary): after performing these actions we invoke surveyActions.save()
// so that we get the survey.state from the server. This isn't strictly
// necessary because we can (and probably should) compute this on the
// client side to show/hide the launch button (in fact, we already compute
// this info on the client side!). Previously all changes in the SurveyForm
// affected a survey directly, but now a change can go to a single RespondentGroup
// and this can affect a Survey, but we don't get a Survey back from updating
// a RespondentGroup. My suggestion is to not rely on the server info and
// only rely on the client side one (in any case the server already computes
// this info and won't allow launching a non-ready survey)

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

const handleRespondentGroupUpload = (dispatch, promise, groupId = null) => {
  promise.then(response => {
    const group = response.entities.respondentGroups[response.result]
    if (groupId) dispatch(doneUploadingExistingRespondentGroup(groupId))
    dispatch(receiveRespondentGroup(group))
  }, (e) => {
    if (groupId) dispatch(doneUploadingExistingRespondentGroup(groupId))
    e.json().then((value) => {
      dispatch(receiveInvalids(value))
    })
  })
  .then(() => dispatch(surveyActions.save()))
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

