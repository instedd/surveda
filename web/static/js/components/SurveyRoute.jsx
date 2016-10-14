import * as routes from '../routes'

export default (survey => {
  if (survey.state === 'not_ready' || survey.state === 'ready') {
    return routes.editSurvey(survey.projectId, survey.id)
  } else {
    return routes.survey(survey.projectId, survey.id)
  }
})
