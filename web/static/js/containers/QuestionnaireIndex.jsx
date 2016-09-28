import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/questionnaires'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'

class QuestionnaireIndex extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchQuestionnaires(projectId))
  }

  render() {
    const { questionnaires, projectId, router } = this.props
    const title = `${Object.keys(questionnaires).length} ${(Object.keys(questionnaires).length == 1) ? ' questionnaire' : ' questionnaires'}`
    return (
      <div>
        <AddButton text="Add questionnaire" linkPath={`/projects/${projectId}/questionnaires/new`} />
        { (Object.keys(questionnaires).length == 0) ?
          <EmptyPage icon='assignment' title='You have no questionnaires on this project' linkPath={`/projects/${projectId}/questionnaires/new`} />
        :
          <CardTable title={ title } highlight={true}>
            <thead>
              <tr>
                <th>Name</th>
                <th>Modes</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(questionnaires).map((questionnaireId) =>
                <tr key={questionnaireId} onClick={() => router.push(`/projects/${projectId}/questionnaires/${questionnaireId}/edit`)}>
                  <td>
                    { questionnaires[questionnaireId].name }
                  </td>
                  <td>
                    { (questionnaires[questionnaireId].modes || []).join(", ") }
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

export default withRouter(connect(mapStateToProps)(QuestionnaireIndex))
