import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { fetchSurvey } from '../api'

class Survey extends Component {
  componentDidMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      dispatch(actions.fetchSurvey(projectId, surveyId))
    }
  }

  render(params) {
    const { survey } = this.props
    if (!survey) {
      return <p>Loading...</p>
    }

    return (
      <div>
        <h3>Survey view</h3>
        <h4>Name: { survey.name }</h4>
        <br/>
        <br/>
        <Link to={`/projects/${survey.projectId}/surveys/${survey.id}/edit`}>Edit</Link>
        {' '}
        <Link to={`/projects/${survey.projectId}/surveys`}>Back</Link>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  surveyId: ownProps.params.id,
  survey: state.surveys[ownProps.params.id] || {}
})

export default withRouter(connect(mapStateToProps)(Survey))
