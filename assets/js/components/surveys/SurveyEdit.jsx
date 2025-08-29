import React, { PropTypes, Component } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import * as actions from "../../actions/survey"
import * as projectActions from "../../actions/project"
import * as channelsActions from "../../actions/channels"
import * as questionnairesActions from "../../actions/questionnaires"
import * as respondentGroupsActions from "../../actions/respondentGroups"
import SurveyForm from "./SurveyForm"
import * as routes from "../../routes"
import { translate } from "react-i18next"

class SurveyEdit extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    projectId: PropTypes.any.isRequired,
    unusedSample: PropTypes.array,
    surveyId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    channels: PropTypes.object,
    project: PropTypes.object,
    respondentGroups: PropTypes.object,
    respondentGroupsUploading: PropTypes.bool,
    respondentGroupsImporting: PropTypes.bool,
    respondentGroupsUploadingExisting: PropTypes.object,
    invalidRespondents: PropTypes.object,
    invalidGroup: PropTypes.bool,
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
      dispatch(projectActions.fetchProject(projectId))
      dispatch(channelsActions.fetchProjectChannels(projectId))
      dispatch(
        questionnairesActions.fetchQuestionnaires(projectId, {
          archived: false,
        })
      )
      dispatch(respondentGroupsActions.fetchRespondentGroups(projectId, surveyId))
    }
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state && survey.state != "not_ready" && survey.state != "ready") {
      router.replace(routes.survey(survey.projectId, survey.id))
    }
  }

  render() {
    const {
      survey,
      projectId,
      project,
      unusedSample,
      questionnaires,
      dispatch,
      channels,
      respondentGroups,
      respondentGroupsUploading,
      respondentGroupsImporting,
      respondentGroupsUploadingExisting,
      invalidRespondents,
      invalidGroup,
      t,
    } = this.props
    const activeQuestionnaires = Object.keys(questionnaires)
      .filter((id) => !questionnaires[id].archived)
      .reduce((activeQuestionnaires, id) => {
        activeQuestionnaires[id] = questionnaires[id]
        return activeQuestionnaires
      }, {})

    if (Object.keys(survey).length == 0 || !respondentGroups) {
      return <div>{t("Loading...")}</div>
    }

    const readOnly = !project || project.readOnly

    let questionnaireIds = survey.questionnaireIds || []
    let questionnaire = null
    if (questionnaireIds.length == 1) {
      questionnaire = questionnaires[questionnaireIds[0]]
    }

    return (
      <div className="white">
        <SurveyForm
          survey={survey}
          respondentGroups={respondentGroups}
          respondentGroupsUploading={respondentGroupsUploading}
          respondentGroupsImporting={respondentGroupsImporting}
          respondentGroupsUploadingExisting={respondentGroupsUploadingExisting}
          invalidRespondents={invalidRespondents}
          invalidGroup={invalidGroup}
          projectId={projectId}
          unusedSample={unusedSample}
          questionnaires={activeQuestionnaires}
          channels={channels}
          dispatch={dispatch}
          questionnaire={questionnaire}
          readOnly={readOnly}
        />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  unusedSample: state.unusedSample,
  surveyId: ownProps.params.surveyId,
  channels: state.channels.items,
  questionnaires: state.questionnaires.items || {},
  respondentGroups: state.respondentGroups.items || {},
  respondentGroupsUploading: state.respondentGroups.uploading,
  respondentGroupsImporting: state.respondentGroups.importing,
  respondentGroupsUploadingExisting: state.respondentGroups.uploadingExisting,
  invalidRespondents: state.respondentGroups.invalidRespondents,
  invalidGroup: state.respondentGroups.invalidRespondentsForGroup,
  survey: state.survey.data || {},
})

export default translate()(withRouter(connect(mapStateToProps)(SurveyEdit)))
