import React, { PropTypes, Component } from 'react'
import merge from 'lodash/merge'
import { Link, withRouter } from 'react-router'
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
    const { dispatch, projectId, router } = this.props
    updateSurvey(survey.projectId, survey)
      .then(survey => dispatch(actions.updateSurvey(survey)))
      .then(() => router.push(`/projects/${survey.projectId}/surveys/${survey.id}/edit/respondents`))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  render() {
    let input
    let questionnaires_input = []
    const { survey, questionnaires } = this.props
    if (!survey || !questionnaires) {
      return <div>Loading...</div>
    }
    return (
      <div className="col s12 m7 offset-m1">
        <div className="row">
          <div className="col s12">
            <h4>Select a questionnaire</h4>
            <p className="flow-text">
              The selected questionnaire will be sent over the survey channels to every respondent until a cutoff rule is reached. If you wish, you can try an experiment to compare questionnaires performance.
            </p>
          </div>
        </div>
        <div className="row">
          <div className="input-field col s12">
            <input id="survey_name" type="text" placeholder="Survey name" defaultValue={survey.name} ref={ node => { input = node } }/>
            <label className="active" htmlFor="survey_name">Survey Name</label>
          </div>
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
        <button type="button" className="btn waves-effect waves-light" onClick={() =>
          this.handleSubmit(merge({}, survey, {name: input.value, questionnaire_id: (questionnaires_input.find(element => element.node.checked) || {}).id }))
        }>
          Submit
        </button>
        <Link  className="btn btn-flat waves-effect waves-light" to={`/projects/${survey.projectId}/surveys`}> Back</Link>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaires: state.questionnaires,
  projectId: ownProps.params.projectId,
  survey: state.surveys[ownProps.params.id]
})

export default withRouter(connect(mapStateToProps)(SurveyQuestionnaireStep));