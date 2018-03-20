import { combineReducers } from 'redux'
import { routerReducer as routing } from 'react-router-redux'
import authorizations from './authorizations'
import projects from './projects'
import project from './project'
import surveys from './surveys'
import respondentsStats from './respondentsStats'
import questionnaires from './questionnaires'
import questionnaire from './questionnaire'
import survey from './survey'
import autoSaveStatus from './autoSaveStatus'
import channels from './channels'
import guisso from './guisso'
import respondents from './respondents'
import respondentGroups from './respondentGroups'
import respondentsCount from './respondentsCount'
import timezones from './timezones'
import collaborators from './collaborators'
import guest from './guest'
import invite from './invite'
import userSettings from './userSettings'
import ui from './ui/index'
import activities from './activities'

export default combineReducers({
  authorizations,
  routing,
  project,
  projects,
  surveys,
  respondentsStats,
  questionnaire,
  questionnaires,
  survey,
  autoSaveStatus,
  respondents,
  respondentGroups,
  respondentsCount,
  channels,
  guisso,
  timezones,
  collaborators,
  activities,
  guest,
  invite,
  userSettings,
  ui
})
