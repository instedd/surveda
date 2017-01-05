// @flow weak
import * as api from '../api'

export const RECEIVE_QUESTIONNAIRES = 'QUESTIONNAIRES_RECEIVE'
export const FETCH_QUESTIONNAIRES = 'QUESTIONNAIRES_FETCH'
export const NEXT_QUESTIONNAIRES_PAGE = 'QUESTIONNAIRES_NEXT_PAGE'
export const PREVIOUS_QUESTIONNAIRES_PAGE = 'QUESTIONNAIRES_PREVIOUS_PAGE'
export const SORT_QUESTIONNAIRES = 'QUESTIONNAIRES_SORT'

export const fetchQuestionnaires = (projectId) => (dispatch, getState) => {
  const state = getState()

  // Don't fetch questionnaires if they are already being fetched
  // for that same project
  if (state.questionnaires.fetching && state.questionnaires.projectId == projectId) {
    return Promise.resolve(getState().questionnaires.items)
  }

  dispatch(startFetchingQuestionnaires(projectId))

  return api
    .fetchQuestionnaires(projectId)
    .then(response => dispatch(receiveQuestionnaires(projectId, response.entities.questionnaires || {})))
    .then(() => getState().questionnaires.items)
}

export const startFetchingQuestionnaires = (projectId) => ({
  type: FETCH_QUESTIONNAIRES,
  projectId
})

export const receiveQuestionnaires = (projectId, questionnaires) => ({
  type: RECEIVE_QUESTIONNAIRES,
  projectId,
  questionnaires
})

export const nextQuestionnairesPage = () => ({
  type: NEXT_QUESTIONNAIRES_PAGE
})

export const previousQuestionnairesPage = () => ({
  type: PREVIOUS_QUESTIONNAIRES_PAGE
})

export const sortQuestionnairesBy = (property) => ({
  type: SORT_QUESTIONNAIRES,
  property
})
