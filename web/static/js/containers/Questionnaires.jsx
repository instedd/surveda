import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/questionnaires'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'

class Questionnaires extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchQuestionnaires(projectId))
  }

  render() {
    const { questionnaires, projectId } = this.props
    const title = `${Object.keys(questionnaires).length} ${(Object.keys(questionnaires).length == 1) ? ' questionnaire' : ' questionnaires'}`
    return (
      <div>
        <AddButton text="Add questionnaire" linkPath={`/projects/${projectId}/questionnaires/new`} />
        { (Object.keys(questionnaires).length == 0) ?
          <EmptyPage icon='assignment' title='You have no questionnaires on this project' linkPath={`/projects/${projectId}/questionnaires/new`} />
        :
          <CardTable title={ title }>
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
          </CardTable>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaires: state.questionnaires
})

export default connect(mapStateToProps)(Questionnaires)
