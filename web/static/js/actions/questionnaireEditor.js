export const SELECT_STEP = 'QUESTIONNAIRE_EDITOR_SELECT_STEP'
export const DESELECT_STEP = 'QUESTIONNAIRE_EDITOR_DESELECT_STEP'
export const INITIALIZE_EDITOR = 'QUESTIONNAIRE_EDITOR_INITIALIZE'
export const NEW_QUESTIONNAIRE = 'QUESTIONNAIRE_NEW'
export const CHANGE_QUESTIONNAIRE_NAME = 'QUESTIONNAIRE_EDITOR_CHANGE_QUESTIONNAIRE_NAME'
export const CHANGE_QUESTIONNAIRE_MODES = 'QUESTIONNAIRE_EDITOR_CHANGE_QUESTIONNAIRE_MODES'
export const CHANGE_STEP_TITLE = 'QUESTIONNAIRE_EDITOR_CHANGE_STEP_TITLE'

export const selectStep = (stepId) => ({
  type: SELECT_STEP,
  stepId
})

export const deselectStep = () => ({
  type: DESELECT_STEP
})

export const initializeEditor = (questionnaire) => ({
  type: INITIALIZE_EDITOR,
  questionnaire
})

export const newQuestionnaire = (projectId) => ({
  type: NEW_QUESTIONNAIRE,
  projectId
})

export const changeQuestionnaireName = (newName) => ({
  type: CHANGE_QUESTIONNAIRE_NAME,
  newName
})

export const changeQuestionnaireModes = (newModes) => ({
  type: CHANGE_QUESTIONNAIRE_MODES,
  newModes
})

export const changeStepTitle = (newTitle) => ({
  type: CHANGE_STEP_TITLE,
  newTitle
})
