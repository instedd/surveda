import { combineReducers } from 'redux'
import { routerReducer as routing } from 'react-router-redux'
import projects from './projects'
import surveys from './surveys'
import respondentsStats from './respondentsStats'
import questionnaires from './questionnaires'
import questionnaireEditor from './questionnaireEditor'
import surveyEdit from './surveyEdit'
import channels from './channels'
import guisso from './guisso'
import respondents from './respondents'

export default combineReducers({
  routing,
  projects,
  surveys,
  respondentsStats,
  questionnaires,
  questionnaireEditor,
  surveyEdit,
  respondents,
  channels,
  guisso
})
