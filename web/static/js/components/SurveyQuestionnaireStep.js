import React, { PropTypes, Component } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey } from '../api'
import * as actions from '../actions/surveys'

class SurveyQuestionnaireStep extends Component {

  handleSubmit(survey) {
    const { dispatch, projectId } = this.props
    updateSurvey(projectId, survey).then(survey => dispatch(actions.updateSurvey(survey))).then(() => browserHistory.push(`/projects/${projectId}/surveys/`)).catch((e) => dispatch(actions.fetchSurveysError(e)))
  }

  render() {
    let input
    const { survey } = this.props
    if (!survey) {
      return <div>Loading...</div>
    }
    return (
      <div className="col-md-8">
        <label>Select a questionnaire</label>
        <div>
          The selected questionnaire will be sent over the survey channels to every respondent until a cutoff rule is reached. If you wish, you can try an experiment to compare questionnaires performance.
        </div>
        <label>Survey Name</label>
        <div>
          <input type="text" placeholder="Survey name" defaultValue={survey.name} ref={ node => { input = node } }/>
        </div>
        <br/>
        <button type="button" onClick={() =>
          this.handleSubmit(merge({}, survey, {name: input.value}))
        }>
          Submit
        </button>
        <Link to={`/projects/${survey.projectId}/surveys`}> Back</Link>
      </div>
    )
  }

}

const mapStateToProps = (state, ownProps) => {
  return{
    survey: state.surveys[ownProps.params.id]
  }
}

export default connect(mapStateToProps)(SurveyQuestionnaireStep);