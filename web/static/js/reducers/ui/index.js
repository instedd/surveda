import { combineReducers } from "redux"
import questionnaireEditor from "./questionnaireEditor"
import surveyWizard from "./surveyWizard"

const data = combineReducers({
  questionnaireEditor,
  surveyWizard,
})

export default combineReducers({ data })
