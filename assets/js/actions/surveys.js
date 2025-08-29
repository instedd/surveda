// @flow
import * as api from "../api"

export const RECEIVE = "RECEIVE_SURVEYS"
export const RECEIVE_UNUSED_SAMPLE_SURVEYS = "RECEIVE_UNUSED_SAMPLE_SURVEYS"
export const FETCHING_UNUSED_SAMPLE_SURVEYS = "FETCHING_UNUSED_SAMPLE_SURVEYS"
export const FETCH = "FETCH_SURVEYS"
export const NEXT_PAGE = "SURVEYS_NEXT_PAGE"
export const PREVIOUS_PAGE = "SURVEYS_PREVIOUS_PAGE"
export const SORT = "SURVEYS_SORT"
export const DELETED = "SURVEY_DELETED"
export const FOLDER_CHANGED = "SURVEY_FOLDER_CHANGED"

export const fetchSurveys =
  (projectId: number) =>
  (dispatch: Function, getState: () => Store): Promise<?SurveyList> => {
    const state = getState()

    // Don't fetch surveys if they are already being fetched
    // for that same project
    if (
      state.surveys.fetching &&
      state.surveys.filter &&
      state.surveys.filter.projectId == projectId
    ) {
      return Promise.resolve(getState().surveys.items)
    }
    dispatch(startFetchingSurveys(projectId))

    return api
      .fetchSurveys(projectId)
      .then((response) => dispatch(receiveSurveys(projectId, response.entities.surveys || {})))
      .then(() => getState().surveys.items)
  }

export const fetchUnusedSample = (projectId: number) => (dispatch: Function, getState: () => Store): Promise => {
  dispatch(fetchingUnusedSampleSurveys())
  return api.fetchUnusedSampleSurveys(projectId).then((surveys) => {
    dispatch(receiveUnusedSampleSurveys(surveys))
  })
}

export const fetchingUnusedSampleSurveys = () => ({
  type: FETCHING_UNUSED_SAMPLE_SURVEYS
})

export const receiveUnusedSampleSurveys = (surveys: Array) => ({
  type: RECEIVE_UNUSED_SAMPLE_SURVEYS,
  surveys
})

export const startFetchingSurveys = (projectId: number) => ({
  type: FETCH,
  projectId,
})

export const receiveSurveys = (
  projectId: number,
  items: IndexedList<SurveyPreview>
): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  projectId,
  items,
})

export const deleted = (survey: Survey) => ({
  type: DELETED,
  id: survey.id,
})

export const folderChanged = (surveyId: number, folderId: number) => ({
  type: FOLDER_CHANGED,
  surveyId,
  folderId,
})

export const nextSurveysPage = () => ({
  type: NEXT_PAGE,
})

export const previousSurveysPage = () => ({
  type: PREVIOUS_PAGE,
})

export const sortSurveysBy = (property: string) => ({
  type: SORT,
  property,
})
