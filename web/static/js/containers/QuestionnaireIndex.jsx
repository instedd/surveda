import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/questionnaires'
import * as projectActions from '../actions/project'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'
import UntitledIfEmpty from '../components/UntitledIfEmpty'
import * as routes from '../routes'

class QuestionnaireIndex extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    // Fetch project for title
    dispatch(projectActions.fetchProject(projectId))
    dispatch(actions.fetchQuestionnaires(projectId))
  }

  render() {
    const { questionnaires, projectId, router } = this.props
    const title = `${Object.keys(questionnaires).length} ${(Object.keys(questionnaires).length === 1) ? ' questionnaire' : ' questionnaires'}`
    return (
      <div>
        <AddButton text='Add questionnaire' linkPath={routes.newQuestionnaire(projectId)} />
        { (Object.keys(questionnaires).length === 0)
          ? <EmptyPage icon='assignment' title='You have no questionnaires on this project' linkPath={routes.newQuestionnaire(projectId)} />
        : (
          <CardTable title={title} highlight>
            <thead>
              <tr>
                <th>Name</th>
                <th>Modes</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(questionnaires).map((questionnaireId) => {
                return (
                  <tr key={questionnaireId} onClick={() => router.push(routes.editQuestionnaire(projectId, questionnaireId))}>
                    <td>
                      <UntitledIfEmpty text={questionnaires[questionnaireId].name} />
                    </td>
                    <td>
                      { (questionnaires[questionnaireId].modes || []).join(', ') }
                    </td>
                  </tr>
                )
              }
              )}
            </tbody>
          </CardTable>
          )
        }
      </div>
    )
  }
}

QuestionnaireIndex.propTypes = {
  dispatch: PropTypes.func.isRequired,
  projectId: PropTypes.number,
  questionnaires: PropTypes.object,
  router: PropTypes.object
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaires: state.questionnaires
})

export default withRouter(connect(mapStateToProps)(QuestionnaireIndex))
