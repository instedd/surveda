export const FETCH = 'QUESTIONNAIRE_FETCH'
export const RECEIVE = 'QUESTIONNAIRE_RECEIVE'

export const receive = (questionnaire) => ({
  type: RECEIVE,
  questionnaire
})

export const fetch = (projectId, questionnaireId) => ({
  type: FETCH,
  projectId,
  questionnaireId
})
