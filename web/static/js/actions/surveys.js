// @flow
import * as api from '../api'

export const RECEIVE = 'SURVEYS_RECEIVE'
export const FETCH = 'SURVEYS_FETCH'
export const NEXT_PAGE = 'SURVEYS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'SURVEYS_PREVIOUS_PAGE'
export const SORT = 'SURVEYS_SORT'
export const DELETED = 'SURVEY_DELETED'

export const fetchSurveys = (projectId: number, folderId: any) => (dispatch: Function, getState: () => Store): Promise<?SurveyList> => {
  const state = getState()

  // Don't fetch surveys if they are already being fetched
  // for that same project
  if (state.surveys.fetching && state.surveys.filter && state.surveys.filter.projectId == projectId) {
    return Promise.resolve(getState().surveys.items)
  }
  dispatch(startFetchingSurveys(projectId, folderId))

  return api
    .fetchSurveys(projectId, folderId)
    .then(response => dispatch(receiveSurveys(projectId, response.entities.surveys || {})))
    .then(() => getState().surveys.items)
}

export const startFetchingSurveys = (projectId: number, folderId?: number) => ({
  type: FETCH,
  projectId,
  folderId
})

export const receiveSurveys = (projectId: number, items: IndexedList<SurveyPreview>): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  projectId,
  items
})

export const deleted = (survey: Survey) => ({
  type: DELETED,
  id: survey.id
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
