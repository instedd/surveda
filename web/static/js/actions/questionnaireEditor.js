export const SELECT_STEP = 'QUESTIONNAIRE_EDITOR_SELECT_STEP'
export const DESELECT_STEP = 'QUESTIONNAIRE_EDITOR_DESELECT_STEP'

export const selectStep = (stepId) => ({
  type: SELECT_STEP,
  stepId
})

export const deselectStep = () => ({
  type: DESELECT_STEP,
})
