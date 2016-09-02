import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { fetchSurveys, fetchSurvey, updateSurvey } from '../api'
import Survey from './Survey'
import SurveyForm from '../components/SurveyForm'

class EditSurvey extends Component {
  componentDidMount() {
    const { dispatch, surveyId, projectId } = this.props
    if(projectId && surveyId) {
      fetchSurvey(projectId, surveyId).then(survey => dispatch(actions.fetchSurveysSuccess(survey)))
    }
  }

  componentDidUpdate() {
  }

  render(params) {
    let input
    const { children, survey } = this.props
    return (<SurveyForm survey={survey} >{children}</SurveyForm>)
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.id,
    survey: state.surveys[ownProps.params.id] || {}
  }
}

export default withRouter(connect(mapStateToProps)(EditSurvey))
