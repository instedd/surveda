import { combineReducers } from 'redux'
import questionnaireEditor from './questionnaireEditor'
import surveyWizard from './surveyWizard'

const errors = (state = {}, action) => {
  return state
}

const data = combineReducers({
  questionnaireEditor,
  surveyWizard
})

export default combineReducers({
  data, errors
})
