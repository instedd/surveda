import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, browserHistory } from 'react-router'
import * as actions from '../actions/questionnaires'
import { fetchQuestionnaires } from '../api'
import { ProjectTabs } from '../components'

class Questionnaires extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    fetchQuestionnaires(projectId).then(questionnaires => dispatch(actions.fetchQuestionnairesSuccess(questionnaires)))
  }

  componentDidUpdate() {
  }

  render() {
    const { questionnaires, projectId } = this.props
    return (
      <div>
        <p style={{fontSize: 'larger'}}>
          <Link to={`/projects/${projectId}/questionnaires/new`}>Add questionnaire</Link>
        </p>
        <table style={{width: '300px'}}>
          <thead>
            <tr>
              <th>Name</th>
              <th>Modes</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            { Object.keys(questionnaires).map((questionnaireId) =>
              <tr key={questionnaireId}>
                <td>
                  { questionnaires[questionnaireId].name }
                </td>
                <td>
                  { (questionnaires[questionnaireId].modes || []).join(", ") }
                </td>
                <td>
                  <Link to={`/projects/${projectId}/questionnaires/${questionnaireId}/edit`}>Edit</Link>
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
    questionnaires: state.questionnaires
  }
}

export default connect(mapStateToProps)(Questionnaires)
