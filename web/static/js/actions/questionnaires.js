export const FETCH_QUESTIONNAIRES_SUCCESS = 'FETCH_QUESTIONNAIRES_SUCCESS'
export const CREATE_QUESTIONNAIRE = 'CREATE_QUESTIONNAIRE'
export const UPDATE_QUESTIONNAIRE = 'UPDATE_QUESTIONNAIRE'
export const FETCH_QUESTIONNAIRES_ERROR = 'FETCH_QUESTIONNAIRES_ERROR'

export const fetchQuestionnairesSuccess = (response) => ({
  type: FETCH_QUESTIONNAIRES_SUCCESS,
  response
})

export const createQuestionnaire = (response) => ({
  type: CREATE_QUESTIONNAIRE,
  id: response.result,
  questionnaire: response.entities.questionnaires[response.result]
})

export const updateQuestionnaire = (response) => ({
  type: UPDATE_QUESTIONNAIRE,
  id: response.result,
  questionnaire: response.entities.questionnaires[response.result]
})

export const fetchQuestionnairesError = (error) => ({
  type: FETCH_QUESTIONNAIRES_ERROR,
  error
})
