export const SELECT_STEP = 'QUESTIONNAIRE_EDITOR_SELECT_STEP'
export const DESELECT_STEP = 'QUESTIONNAIRE_EDITOR_DESELECT_STEP'
export const INITIALIZE_EDITOR = 'QUESTIONNAIRE_EDITOR_INITIALIZE'
export const NEW_QUESTIONNAIRE = 'QUESTIONNAIRE_NEW'
export const CHANGE_QUESTIONNAIRE_NAME = 'QUESTIONNAIRE_EDITOR_CHANGE_QUESTIONNAIRE_NAME'
export const TOGGLE_QUESTIONNAIRE_MODE = 'QUESTIONNAIRE_EDITOR_TOGGLE_QUESTIONNAIRE_MODE'
export const CHANGE_STEP_TITLE = 'QUESTIONNAIRE_EDITOR_CHANGE_STEP_TITLE'
export const CHANGE_STEP_SMS_PROMPT = 'QUESTIONNAIRE_EDITOR_CHANGE_STEP_SMS_PROMPT'
export const CHANGE_STEP_STORE = 'QUESTIONNAIRE_EDITOR_CHANGE_STEP_STORE'
export const ADD_STEP = 'QUESTIONNAIRE_EDITOR_ADD_STEP'
export const DELETE_STEP = 'QUESTIONNAIRE_EDITOR_DELETE_STEP'
export const ADD_CHOICE = 'QUESTIONNAIRE_EDITOR_ADD_CHOICE'
export const DELETE_CHOICE = 'QUESTIONNAIRE_EDITOR_DELETE_CHOICE'
export const CHANGE_CHOICE = 'QUESTIONNAIRE_EDITOR_CHANGE_CHOICE'

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

export const toggleQuestionnaireMode = (mode) => ({
  type: TOGGLE_QUESTIONNAIRE_MODE,
  mode
})

export const changeStepTitle = (newTitle) => ({
  type: CHANGE_STEP_TITLE,
  newTitle
})

export const changeStepPromptSms = (newPrompt) => ({
  type: CHANGE_STEP_SMS_PROMPT,
  newPrompt
})

export const changeStepStore = (newStore) => ({
  type: CHANGE_STEP_STORE,
  newStore
})

export const addStep = (stepType) => ({
  type: ADD_STEP,
  stepType
})

export const deleteStep = (step) => ({
  type: DELETE_STEP
})

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
