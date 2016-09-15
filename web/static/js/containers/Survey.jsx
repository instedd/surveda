import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import * as respondentActions from '../actions/respondents'
import { fetchSurvey } from '../api'

class Survey extends Component {
  componentDidMount() {
    const { dispatch, projectId, surveyId, router } = this.props
    if (projectId && surveyId) {
      dispatch(actions.fetchSurvey(projectId, surveyId))
        .then((survey) => {
          if (survey.state == "pending") {
            router.push(`/projects/${survey.projectId}/surveys/${survey.id}/edit`)
          }
        })
      dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
    }
  }

  render(params) {
    const { survey, router, respondentsStats } = this.props
    if (!survey) {
      return <p>Loading...</p>
    }

    return (
      <div>
        <h3>{ survey.name }</h3>
        <br/>
        <table className="ncdtable">
          <thead>
            <tr>
              <th>Pending</th>
              <th>Completed</th>
              <th>Active</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{ respondentsStats.pending }</td>
              <td>{ respondentsStats.completed }</td>
              <td>{ respondentsStats.active }</td>
            </tr>
          </tbody>
        </table>
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
  surveyId: ownProps.params.surveyId,
  survey: state.surveys[ownProps.params.surveyId] || {},
  respondentsStats: state.respondentsStats[ownProps.params.surveyId] || {},
})

export default withRouter(connect(mapStateToProps)(Survey))
