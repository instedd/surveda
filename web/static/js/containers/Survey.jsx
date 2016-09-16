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

        <div className="row">
          <div className="col s12">
            <div className="card">
              <div className="card-table-title">
                { survey.name }
              </div>
              <div className="card-table">
                <table>
                  <thead>
                    <tr>
                      <th>Pending</th>
                      <th>Active</th>
                      <th>Completed</th>
                      <th>Failed</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>{ respondentsStats.pending }</td>
                      <td>{ respondentsStats.active }</td>
                      <td>{ respondentsStats.completed }</td>
                      <td>{ respondentsStats.failed }</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div className="row">
          <div className="col s12">
            <Link className="btn waves-effect waves-light" to={`/projects/${survey.projectId}/surveys/${survey.id}/edit`}>Edit</Link>
            {' '}
            <Link className="btn btn-flat waves-effect waves-light" to={`/projects/${survey.projectId}/surveys`}>Back</Link>
          </div>
        </div>

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
