import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, browserHistory } from 'react-router'
import * as actions from '../actions/surveys'
import { fetchSurveys, createSurvey } from '../api'
import { ProjectTabs } from '../components'

class Surveys extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    fetchSurveys(projectId).then(surveys => dispatch(actions.fetchSurveysSuccess(surveys)))
  }

  componentDidUpdate() {
  }

  newSurvey() {
    const { dispatch, projectId } = this.props
    createSurvey(projectId).then(response => {
      dispatch(actions.createSurvey(response))
      browserHistory.push(`/projects/${projectId}/surveys/${response.result}/edit`)
    })
  }

  render() {
    const { surveys, projectId } = this.props
    return (
      <div>
        <ProjectTabs projectId={projectId}/>
        <p style={{fontSize: 'larger'}}>
          <a href="#" onClick={() => this.newSurvey() }>
            Add survey
          </a>
        </p>
        <table style={{width: '300px'}}>
          <thead>
            <tr>
              <th>Name</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            { Object.keys(surveys).map((survey_id) =>
              <tr key={survey_id}>
                <td>
                  <Link to={`/projects/${projectId}/surveys/${survey_id}`}>{ surveys[survey_id].name }</Link>
                </td>
                <td>
                  <Link to={`/projects/${projectId}/surveys/${survey_id}/edit`}>Edit</Link>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveys: state.surveys
  }
}

export default connect(mapStateToProps)(Surveys)
