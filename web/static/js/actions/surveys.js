// @flow
import * as api from '../api'

export const RECEIVE = 'SURVEYS_RECEIVE'
export const FETCH = 'SURVEYS_FETCH'
export const NEXT_PAGE = 'SURVEYS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'SURVEYS_PREVIOUS_PAGE'
export const SORT = 'SURVEYS_SORT'

export const fetchSurveys = (projectId: number) => (dispatch: Function, getState: () => Store): Promise<?SurveyList> => {
  const state = getState()

  // Don't fetch surveys if they are already being fetched
  // for that same project
  if (state.surveys.fetching && state.surveys.filter && state.surveys.filter.projectId == projectId) {
    return Promise.resolve(getState().surveys.items)
  }

  dispatch(startFetchingSurveys(projectId))

  return api
    .fetchSurveys(projectId)
    .then(response => dispatch(receiveSurveys(projectId, response.entities.surveys || {})))
    .then(() => getState().surveys.items)
}

export const startFetchingSurveys = (projectId: number) => ({
  type: FETCH,
  projectId
})

export const receiveSurveys = (projectId: number, surveys: IndexedList<SurveyPreview>) => ({
  type: RECEIVE,
  projectId,
  surveys
})

export const nextSurveysPage = () => ({
  type: NEXT_PAGE
})

export const previousSurveysPage = () => ({
  type: PREVIOUS_PAGE
})

export const sortSurveysBy = (property: string) => ({
  type: SORT,
  property
})
