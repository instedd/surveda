import * as api from '../api'

export const RECEIVE_RESPONDENT_GROUPS = 'RECEIVE_RESPONDENT_GROUPS'
export const RECEIVE_RESPONDENT_GROUP = 'RECEIVE_RESPONDENT_GROUP'
export const REMOVE_RESPONDENT_GROUP = 'REMOVE_RESPONDENT_GROUP'
export const FETCH_RESPONDENT_GROUPS = 'FETCH_RESPONDENT_GROUPS'
export const INVALID_RESPONDENT_GROUPS = 'INVALID_RESPONDENT_GROUPS'
export const INVALID_RESPONDENTS = 'INVALID_RESPONDENTS'
export const CLEAR_INVALIDS = 'CLEAR_INVALIDS'

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

export const uploadRespondentGroup = (projectId, surveyId, files) => dispatch => {
  api.uploadRespondentGroup(projectId, surveyId, files)
  .then(response => {
    const group = response.entities.respondentGroups[response.result]
    dispatch(receiveRespondentGroup(group))
  }, (e) => {
    e.json().then((value) => {
      dispatch(receiveInvalids(value))
    })
  })
}

export const receiveInvalids = (invalidRespondents) => ({
  type: INVALID_RESPONDENTS,
  invalidRespondents: invalidRespondents
})

export const clearInvalids = () => ({
  type: CLEAR_INVALIDS
})

export const removeRespondentGroup = (projectId, surveyId, groupId) => dispatch => {
  api.removeRespondentGroup(projectId, surveyId, groupId)
  .then(response => {
    dispatch({
      type: REMOVE_RESPONDENT_GROUP,
      id: groupId
    })
  })
}
