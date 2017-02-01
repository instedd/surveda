import * as api from '../api'
import * as surveyActions from './survey'

export const RECEIVE_RESPONDENT_GROUPS = 'RECEIVE_RESPONDENT_GROUPS'
export const RECEIVE_RESPONDENT_GROUP = 'RECEIVE_RESPONDENT_GROUP'
export const REMOVE_RESPONDENT_GROUP = 'REMOVE_RESPONDENT_GROUP'
export const FETCH_RESPONDENT_GROUPS = 'FETCH_RESPONDENT_GROUPS'
export const INVALID_RESPONDENT_GROUPS = 'INVALID_RESPONDENT_GROUPS'
export const INVALID_RESPONDENTS = 'INVALID_RESPONDENTS'
export const CLEAR_INVALIDS = 'CLEAR_INVALIDS'
export const SELECT_CHANNELS = 'SURVEY_SELECT_CHANNELS'

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
  api.uploadRespondentGroup(projectId, surveyId, files)
  .then(response => {
    const group = response.entities.respondentGroups[response.result]
    dispatch(receiveRespondentGroup(group))
  }, (e) => {
    e.json().then((value) => {
      dispatch(receiveInvalids(value))
    })
  })
  .then(() => dispatch(surveyActions.save()))
}

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

