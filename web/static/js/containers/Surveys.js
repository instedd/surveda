import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import { ProjectTabs } from '../components'

class Surveys extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchSurveys(projectId))
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    createSurvey(projectId).then(response => {
      dispatch(actions.createSurvey(response))
      router.push(`/projects/${projectId}/surveys/${response.result}/edit`)
    })
  }

  render() {
    const { surveys, projectId } = this.props
    return (
      <div>
        <a className="btn-floating btn-large waves-effect waves-light green right mtop tooltipped" data-position="top" data-delay="20" data-tooltip="Add survey" href="#" onClick={() => this.newSurvey() }>
          <i className="material-icons">add</i>
        </a>
        <table className="ncdtable">
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

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveys: state.surveys
})

export default withRouter(connect(mapStateToProps)(Surveys))
