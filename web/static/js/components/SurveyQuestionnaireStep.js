import React, { PropTypes, Component } from 'react'
import { browserHistory } from 'react-router'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey } from '../api'
import * as actions from '../actions/surveys'
import * as questionnairesActions from '../actions/questionnaires'

class SurveyQuestionnaireStep extends Component {
  componentDidMount() {
    const { dispatch, projectId, questionnaires } = this.props
    if (projectId) {
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
    }
  }

  handleSubmit(survey) {
    const { dispatch, projectId } = this.props
    updateSurvey(survey.projectId, survey).then(survey => dispatch(actions.updateSurvey(survey))).then(() => browserHistory.push(`/projects/${survey.projectId}/surveys/`)).catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  render() {
    let input
    let questionnaires_input = []
    const { survey, questionnaires } = this.props
    if (!survey || !questionnaires) {
      return <div>Loading...</div>
    }
    return (
      <div className="col s8">
        <label>Select a questionnaire</label>
        <div>
          The selected questionnaire will be sent over the survey channels to every respondent until a cutoff rule is reached. If you wish, you can try an experiment to compare questionnaires performance.
        </div>
        <label>Survey Name</label>
        <div>
          <input type="text" placeholder="Survey name" defaultValue={survey.name} ref={ node => { input = node } }/>
        </div>
        <h6>Questionnaires</h6>
        { Object.keys(questionnaires).map((questionnaire_id) =>
          <div key={questionnaire_id}>
            <p>
              <input id={questionnaire_id} type="radio" name="questionnaire" className="with-gap" value={ questionnaire_id } ref={ node => {questionnaires_input.push({id: questionnaire_id, node:node}) } } defaultChecked={survey.questionnaireId == questionnaire_id } />
              <label htmlFor={questionnaire_id}>{ questionnaires[questionnaire_id].name }</label>
            </p>
          </div>
        )}

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

const mapStateToProps = (state, ownProps) => ({
  questionnaires: state.questionnaires,
  projectId: ownProps.params.projectId,
  survey: state.surveys[ownProps.params.id]
})

export default connect(mapStateToProps)(SurveyQuestionnaireStep);