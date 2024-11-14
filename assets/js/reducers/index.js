import { combineReducers } from "redux"
import { routerReducer as routing } from "react-router-redux"
import authorizations from "./authorizations"
import autoSaveStatus from "./autoSaveStatus"
import channel from "./channel"
import channels from "./channels"
import collaborators from "./collaborators"
import guest from "./guest"
import guisso from "./guisso"
import invite from "./invite"
import project from "./project"
import projects from "./projects"
import questionnaire from "./questionnaire"
import questionnaires from "./questionnaires"
import respondentGroups from "./respondentGroups"
import respondents from "./respondents"
import respondentsCount from "./respondentsCount"
import respondentsStats from "./respondentsStats"
import respondentsFiles from "./respondentsFiles"
import survey from "./survey"
import surveys from "./surveys"
import timezones from "./timezones"
import ui from "./ui/index"
import userSettings from "./userSettings"
import activities from "./activities"
import integrations from "./integrations"
import folder from "./folder"
import folders from "./folders"
import surveyStats from "./surveyStats"
import surveyRetriesHistograms from "./surveyRetriesHistograms"
import panelSurveys from "./panelSurveys"
import panelSurvey from "./panelSurvey"

export default combineReducers({
  activities,
  authorizations,
  autoSaveStatus,
  channel,
  channels,
  collaborators,
  guest,
  guisso,
  invite,
  project,
  projects,
  questionnaire,
  questionnaires,
  respondentGroups,
  respondents,
  respondentsCount,
  respondentsFiles,
  respondentsStats,
  routing,
  survey,
  surveys,
  timezones,
  ui,
  userSettings,
  integrations,
  folder,
  folders,
  surveyStats,
  surveyRetriesHistograms,
  panelSurveys,
  panelSurvey,
})
