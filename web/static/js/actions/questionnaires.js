// @flow
import * as api from '../api'

export const RECEIVE = 'QUESTIONNAIRES_RECEIVE'
export const FETCH = 'QUESTIONNAIRES_FETCH'
export const NEXT_PAGE = 'QUESTIONNAIRES_NEXT_PAGE'
export const PREVIOUS_PAGE = 'QUESTIONNAIRES_PREVIOUS_PAGE'
export const SORT = 'QUESTIONNAIRES_SORT'
export const DELETED = 'QUESTIONNAIRES_DELETED'

export const fetchQuestionnaires = (projectId: number, options: Object) => (dispatch: Function, getState: () => Store): Promise<?QuestionnaireList> => {
  const state = getState()

  // Don't fetch questionnaires if they are already being fetched
  // for that same project
  if (state.questionnaires.fetching && state.questionnaires.filter && state.questionnaires.filter.projectId == projectId) {
    return Promise.resolve(getState().questionnaires.items)
  }

  if (!options) options = {'archived': null}

  dispatch(startFetchingQuestionnaires(projectId, options['archived']))

  return api
    .fetchQuestionnaires(projectId, options)
    .then(response => dispatch(receiveQuestionnaires(projectId, response.entities.questionnaires || {}, options['archived'])))
    .then(() => getState().questionnaires.items)
}

export const startFetchingQuestionnaires = (projectId: number, archived: ?boolean) => ({
  type: FETCH,
  projectId,
  archived
})

export const receiveQuestionnaires = (projectId: number, items: IndexedList<Questionnaire>, archived: boolean): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  projectId,
  items,
  archived
})

export const nextQuestionnairesPage = () => ({
  type: NEXT_PAGE
})

export const previousQuestionnairesPage = () => ({
  type: PREVIOUS_PAGE
})

export const sortQuestionnairesBy = (property: string) => ({
  type: SORT,
  property
})

export const deleteQuestionnaire = (projectId: number, questionnaire: Questionnaire) => (dispatch: Function, getState: () => Store) => {
  return api
    .deleteQuestionnaire(projectId, questionnaire)
    .then(response => dispatch(deleted(questionnaire)))
}

export const deleted = (questionnaire: Questionnaire) => ({
  type: DELETED,
  id: questionnaire.id
})

export const archiveOrUnarchive = (questionnaire: Questionnaire, action: string) => (dispatch: Function, getState: () => Store) => {
  const archive = (action == 'archive')
  const newQuestionnaire = {
    ...questionnaire,
    archived: archive
  }
  return api.updateQuestionnaireArchived(newQuestionnaire).then(response => {
    return { error: false }
  })
  .catch(async response => {
    const body = await response.json()
    return { error: body.error }
  })
}
