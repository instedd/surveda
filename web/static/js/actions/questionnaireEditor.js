export const INITIALIZE_EDITOR = 'QUESTIONNAIRE_EDITOR_INITIALIZE'
export const NEW_QUESTIONNAIRE = 'QUESTIONNAIRE_NEW'
export const CHANGE_QUESTIONNAIRE_MODES = 'QUESTIONNAIRE_EDITOR_CHANGE_QUESTIONNAIRE_MODES'
export const ADD_CHOICE = 'QUESTIONNAIRE_EDITOR_ADD_CHOICE'
export const DELETE_CHOICE = 'QUESTIONNAIRE_EDITOR_DELETE_CHOICE'
export const CHANGE_CHOICE = 'QUESTIONNAIRE_EDITOR_CHANGE_CHOICE'

export const addChoice = () => ({
  type: ADD_CHOICE
})

export const changeChoice = (index, value, responses) => ({
  type: CHANGE_CHOICE,
  choiceChange: { index, value, responses }
})

export const deleteChoice = (index) => ({
  type: DELETE_CHOICE,
  index
})
