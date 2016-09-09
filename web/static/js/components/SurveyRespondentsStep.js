import React, { PropTypes, Component } from 'react'
import { browserHistory } from 'react-router'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { uploadRespondents, fetchQuestionnaires } from '../api'
import * as actions from '../actions/surveys'
import * as questionnairesActions from '../actions/questionnaires'

class SurveyQuestionnaireStep extends Component {

  componentDidMount() {
    const { dispatch, projectId, questionnaires } = this.props
    if(projectId) {
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
    }
  }

  handleSubmit(survey, files) {
    const { dispatch, projectId } = this.props
    uploadRespondents(survey, files)
      .then(survey => dispatch(actions.updateSurvey(survey)))
      .then(() => browserHistory.push(`/projects/${survey.projectId}/surveys/`))
      .catch((e) => dispatch(actions.fetchSurveysError(e)))
  }

  render() {
    let files
    const { survey, questionnaires } = this.props
    if (!survey || !questionnaires) {
      return <div>Loading...</div>
    }
    return (
      <div className="col s8">
        <h4>Upload your respondents list</h4>
        <div>
          <h5>
            Upload a CSV file like this one with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.
          </h5>
        </div>
        
        <div style={{height: '300px', paddingLeft: '90px', paddingTop: '50px'}} >

          <Dropzone multiple={false} onDrop={file => {files = file}}>
            <div>Drop your CSV file here, or click browse</div>
          </Dropzone>

        </div>

        <br/>
        <button type="button" onClick={() =>
          this.handleSubmit(survey, files)
        }>
          Submit
        </button>
      </div>
    )
  }

}

const mapStateToProps = (state, ownProps) => {
  return{
    questionnaires: state.questionnaires,
    projectId: ownProps.params.projectId,
    survey: state.surveys[ownProps.params.id]
  }
}

export default connect(mapStateToProps)(SurveyQuestionnaireStep);