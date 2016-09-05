import React, { PropTypes, Component } from 'react'
import { browserHistory } from 'react-router'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey, fetchQuestionnaires } from '../api'
import * as actions from '../actions/surveys'
import * as questionnairesActions from '../actions/questionnaires'

class SurveyQuestionnaireStep extends Component {

  componentDidMount() {
    const { dispatch, projectId, questionnaires } = this.props
    if(projectId) {
      fetchQuestionnaires(projectId).then(questionnaires => dispatch(questionnairesActions.fetchQuestionnairesSuccess(questionnaires)))
    }
  }

  handleSubmit(survey) {
    const { dispatch, projectId } = this.props
    updateSurvey(survey.projectId, survey).then(survey => dispatch(actions.updateSurvey(survey))).then(() => browserHistory.push(`/projects/${survey.projectId}/surveys/`)).catch((e) => dispatch(actions.fetchSurveysError(e)))
  }

  render() {
    let input
    let questionnaires_input = []
    const { survey, questionnaires } = this.props
    if (!survey || !questionnaires) {
      return <div>Loading...</div>
    }
    return (
      <div className="col-md-8">
        <label>Select a questionnaire</label>
        <div>
          The selected questionnaire will be sent over the survey channels to every respondent until a cutoff rule is reached. If you wish, you can try an experiment to compare questionnaires performance.
        </div>
        <label>Survey Name</label>
        <div>
          <input type="text" placeholder="Survey name" defaultValue={survey.name} ref={ node => { input = node } }/>
        </div>
        <h4>Questionnaires</h4>
        <table style={{width: '300px'}}>
          <thead>
            <tr>
              <th style={{width: '20px'}}/>
              <th>Name</th>
            </tr>
          </thead>
          <tbody>
            { Object.keys(questionnaires).map((questionnaire_id) =>
              <tr key={questionnaire_id}>
                <td>
                  <input type="radio" name="questionnaire" value={ questionnaire_id } ref={ node => {questionnaires_input.push({id: questionnaire_id, node:node}) } } defaultChecked={survey.questionnaireId == questionnaire_id } />
                </td>
                <td>
                  { questionnaires[questionnaire_id].name }
                </td>
              </tr>
            )}
          </tbody>
        </table>

        <br/>
        <button type="button" onClick={() =>
          this.handleSubmit(merge({}, survey, {name: input.value, questionnaire_id: questionnaires_input.find(element => element.node.checked).id }))
        }>
          Submit
        </button>
        <Link to={`/projects/${survey.projectId}/surveys`}> Back</Link>
      </div>
    )
  }

}

const mapStateToProps = (state, ownProps) => {
  return{
    questionnaires: state.questionnaires,
    projectId: ownProps.params.projectId,
    survey: state.surveys[ownProps.params.id]
  }
}

export default connect(mapStateToProps)(SurveyQuestionnaireStep);