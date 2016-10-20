export const FETCH = 'QUESTIONNAIRE_FETCH'
export const RECEIVE = 'QUESTIONNAIRE_RECEIVE'
export const CHANGE_NAME = 'QUESTIONNAIRE_CHANGE_NAME'

export const receive = (questionnaire) => ({
  type: RECEIVE,
  questionnaire
})

export const fetch = (projectId, questionnaireId) => ({
  type: FETCH,
  projectId,
  questionnaireId
})

export const changeName = (newName) => ({
  type: CHANGE_NAME,
  newName
})
