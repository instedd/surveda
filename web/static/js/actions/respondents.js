import * as api from "../api"

export const RECEIVE_RESPONDENTS = "RECEIVE_RESPONDENTS"
export const FETCH_RESPONDENTS = "FETCH_RESPONDENTS"
export const CREATE_RESPONDENT = "CREATE_RESPONDENT"
export const UPDATE_RESPONDENT = "UPDATE_RESPONDENT"
export const RECEIVE_RESPONDENTS_ERROR = "RECEIVE_RESPONDENTS_ERROR"
export const RECEIVE_RESPONDENTS_STATS = "RECEIVE_RESPONDENTS_STATS"
export const SET_RESPONDENTS_FIELD_SELECTION = "SET_RESPONDENTS_FIELD_SELECTION"

export const fetchRespondents =
  (projectId, surveyId, pageSize, pageNumber, filter = "", sortBy = null, sortAsc = true) =>
  (dispatch, getState) => {
    dispatch(startFetchingRespondents(surveyId, pageSize, pageNumber, filter, sortBy, sortAsc))
    api
      .fetchRespondents(projectId, surveyId, pageSize, pageNumber, filter, sortBy, sortAsc)
      .then((response) => {
        const state = getState().respondents
        const lastFetchResponse =
          state.surveyId == surveyId &&
          state.page.size == pageSize &&
          state.page.number == pageNumber &&
          state.filter == filter &&
          state.sortBy == sortBy &&
          state.sortAsc == sortAsc
        if (lastFetchResponse) {
          dispatch(
            receiveRespondents(
              response.entities.respondents || {},
              response.respondentsCount,
              response.result,
              response.respondentsFields
            )
          )
        }
      })
  }
export const fetchRespondentsStats = (projectId, surveyId) => (dispatch) => {
  api
    .fetchRespondentsStats(projectId, surveyId)
    .then((stats) => dispatch(receiveRespondentsStats(stats)))
}

export const receiveRespondentsStats = (response) => ({
  type: RECEIVE_RESPONDENTS_STATS,
  response,
})

export const receiveRespondents = (respondents, respondentsCount, order, fields) => ({
  type: RECEIVE_RESPONDENTS,
  respondents,
  respondentsCount,
  order,
  fields,
})

export const createRespondent = (response) => ({
  type: CREATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result],
})

export const updateRespondent = (response) => ({
  type: UPDATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result],
})

export const updateRespondentsFilter = (projectId, surveyId, filter) => (dispatch, getState) => {
  const { sortBy, sortAsc, page } = getState().respondents
  dispatch(fetchRespondents(projectId, surveyId, page.size, 1, filter, sortBy, sortAsc))
}

export const setRespondentsFieldSelection = (fieldUniqueKey, selected) => ({
  type: SET_RESPONDENTS_FIELD_SELECTION,
  fieldUniqueKey,
  selected,
})

export const receiveRespondentsError = (error) => ({
  type: RECEIVE_RESPONDENTS_ERROR,
  error,
})

export const startFetchingRespondents = (
  surveyId,
  pageSize,
  pageNumber,
  filter,
  sortBy,
  sortAsc
) => ({
  type: FETCH_RESPONDENTS,
  surveyId,
  pageSize,
  pageNumber,
  filter,
  sortBy,
  sortAsc,
})

export const sortRespondentsBy = (projectId, surveyId, newSortBy) => (dispatch, getState) => {
  const { page, filter, sortBy, sortAsc } = getState().respondents
  const newSortAsc = sortBy == newSortBy ? !sortAsc : true
  dispatch(fetchRespondents(projectId, surveyId, page.size, 1, filter, newSortBy, newSortAsc))
}

export const changePageSize = (projectId, surveyId, pageSize) => (dispatch, getState) => {
  const { filter, sortBy, sortAsc } = getState().respondents
  dispatch(fetchRespondents(projectId, surveyId, pageSize, 1, filter, sortBy, sortAsc))
}
