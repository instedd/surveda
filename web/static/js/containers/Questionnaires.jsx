import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/questionnaires'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'

class Questionnaires extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchQuestionnaires(projectId))
  }

  render() {
    const { questionnaires, projectId } = this.props
    return (
      <div>
        <AddButton text="Add questionnaire" linkPath={`/projects/${projectId}/questionnaires/new`} />
        { (Object.keys(questionnaires).length == 0) ?
          <EmptyPage icon='assignment' title='You have no questionnaires on this project' linkPath={`/projects/${projectId}/questionnaires/new`} />
        :
          <div className="row">
            <div className="col s12">
              <div className="card">
                <div className="card-table-title">
                  { (Object.keys(questionnaires).length == 1) ? ' questionnaire' : ' questionnaires' }
                </div>
                <div className="card-table">
                  <table>
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
              </div>
            </div>
          </div>
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
