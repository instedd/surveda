import * as api from '../api'

export const RECEIVE_RESPONDENTS = 'RECEIVE_RESPONDENTS'
export const CREATE_RESPONDENT = 'CREATE_RESPONDENT'
export const UPDATE_RESPONDENT = 'UPDATE_RESPONDENT'
export const REMOVE_RESPONDENTS = 'REMOVE_RESPONDENTS'
export const RECEIVE_RESPONDENTS_ERROR = 'RECEIVE_RESPONDENTS_ERROR'
export const RECEIVE_RESPONDENTS_STATS = 'RECEIVE_RESPONDENTS_STATS'

export const fetchRespondents = (projectId, surveyId) => dispatch => {
  api.fetchRespondents(projectId, surveyId)
    .then(respondents => dispatch(receiveRespondents(respondents)))
}

export const fetchRespondent = (projectId, respondentId) => dispatch => {
  api.fetchRespondent(projectId, respondentId)
    .then(respondent => dispatch(receiveRespondents(respondent)))
}

export const fetchRespondentsStats = (projectId, surveyId) => dispatch => {
  api.fetchRespondentsStats(projectId, surveyId)
    .then(stats => dispatch(receiveRespondentsStats(surveyId, stats)))
}

export const receiveRespondentsStats = (surveyId, response) => ({
  type: RECEIVE_RESPONDENTS_STATS,
  surveyId: surveyId,
  respondentsStats: {
    respondentsStats: response.result,
    completedByDate: [
      {completed_date: "24-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "25-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "26-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "27-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "28-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "29-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "30-Apr-07", respondents:	Math.random() * 100},
      {completed_date: "01-May-07", respondents:	Math.random() * 100},
      {completed_date: "02-May-07", respondents:	Math.random() * 100},
      {completed_date: "03-May-07", respondents:	Math.random() * 100},
      {completed_date: "04-May-07", respondents:	Math.random() * 100},
      {completed_date: "05-May-07", respondents:	Math.random() * 100},
      {completed_date: "06-May-07", respondents:	Math.random() * 100},
      {completed_date: "07-May-07", respondents:	Math.random() * 100}
    ]
  }
})

export const receiveRespondents = (response) => ({
  type: RECEIVE_RESPONDENTS,
  response
})

export const removeRespondents = (response) => ({
  type: REMOVE_RESPONDENTS,
  response
})

export const createRespondent = (response) => ({
  type: CREATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result]
})

export const updateRespondent = (response) => ({
  type: UPDATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result]
})

export const receiveRespondentsError = (error) => ({
  type: RECEIVE_RESPONDENTS_ERROR,
  error
})
