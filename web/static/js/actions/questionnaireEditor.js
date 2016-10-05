export const SELECT_STEP = 'QUESTIONNAIRE_EDITOR_SELECT_STEP'
export const DESELECT_STEP = 'QUESTIONNAIRE_EDITOR_DESELECT_STEP'
export const INITIALIZE_EDITOR = 'QUESTIONNAIRE_EDITOR_INITIALIZE'

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
