import { combineReducers } from 'redux'
import { routerReducer as routing } from 'react-router-redux'
import projects from './projects'
import surveys from './surveys'
import respondentsStats from './respondentsStats'
import questionnaires from './questionnaires'
import questionnaireEditor from './questionnaireEditor'
import channels from './channels'
import guisso from './guisso'
import respondents from './respondents'
import respondentsCount from './respondentsCount'

export default combineReducers({
  routing,
  projects,
  surveys,
  respondentsStats,
  questionnaires,
  questionnaireEditor,
  respondents,
  respondentsCount,
  channels,
  guisso
})
