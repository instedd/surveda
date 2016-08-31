import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/surveys'
import { fetchSurveys } from '../api'

class Surveys extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    fetchSurveys().then(surveys => dispatch(actions.fetchSurveysSuccess(surveys)))
  }

  componentDidUpdate() {
  }

  render() {
    const { surveys } = this.props
    return (
      <div>
        <p style={{fontSize: 'larger'}}>
          <Link to='/surveys/new'>Add survey</Link>
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
                  <Link to={`project/:projectId/surveys/${survey_id}`}>{ surveys[survey_id].name }</Link>
                </td>
                <td>
                  <Link to={`project/:projectId/surveys/${survey_id}/edit`}>Edit</Link>
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
