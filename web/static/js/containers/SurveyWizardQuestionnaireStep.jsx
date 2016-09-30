import React, { Component } from 'react'
import merge from 'lodash/merge'
import { Link, withRouter } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey } from '../api'
import * as actions from '../actions/surveys'
import * as questionnairesActions from '../actions/questionnaires'

class SurveyWizardQuestionnaireStep extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    if (projectId) {
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
    }
  }

  handleSubmit(oldSurvey, inputValue, questionnairesInput) {
    let newSurveyValues = {
      name: inputValue,
      questionnaire_id: (questionnairesInput.find(element => element.node.checked) || {}).id
    }

    let survey = merge({}, oldSurvey, newSurveyValues)

    const { dispatch, router } = this.props
    updateSurvey(survey.projectId, survey)
      .then(survey => dispatch(actions.updateSurvey(survey)))
      .then(() => router.push(`/projects/${survey.projectId}/surveys/${survey.id}/edit/respondents`))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  newQuestionnaireButton(projectId, questionnaires) {
    let buttonLabel = "NEW QUESTIONNAIRE"
    if (Object.keys(questionnaires).length === 0) {
      buttonLabel = "You still haven't created any questionnaire. Click here to create one."
    }

    return (
      <div className='col s12'>
        <Link className='waves-effect waves-teal btn-flat btn-flat-link' to={`/projects/${projectId}/questionnaires/new`}>
          {buttonLabel}
        </Link>
      </div>
    )
  }

  render() {
    let input
    let questionnaires_input = []
    const { survey, questionnaires, projectId } = this.props
    if (!survey || !questionnaires) {
      return <div>Loading...</div>
    }
    return (
      <div className='col s12 m7 offset-m1'>
        <div className='row'>
          <div className='input-field col s12'>
            <input id='survey_name' type='text' placeholder='Survey name' defaultValue={survey.name} ref={node => { input = node; if (input != null) input.focus() }} />
            <label className='active' htmlFor='survey_name'>Survey Name</label>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <h4>Select a questionnaire</h4>
            <p className='flow-text'>
              The selected questionnaire will be sent over the survey channels to every respondent until a cutoff rule is reached. If you wish, you can try an experiment to compare questionnaires performance.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            { Object.keys(questionnaires).map((questionnaireId) =>
              <div key={questionnaireId}>
                <p>
                  <input id={questionnaireId} type='radio' name='questionnaire' className='with-gap' value={questionnaireId} ref={node => { questionnaires_input.push({id: questionnaireId, node: node}) }} defaultChecked={survey.questionnaireId == questionnaireId} />
                  <label htmlFor={questionnaireId}>{ questionnaires[questionnaireId].name }</label>
                </p>
              </div>
            )}
          </div>
          {this.newQuestionnaireButton(projectId, questionnaires)}
        </div>
        <div className='row'>
          <div className='col s12'>
            <button type='button' className='btn waves-effect waves-light' onClick={() =>
              this.handleSubmit(survey, input.value, questionnaires_input)
            }>
              Next
            </button>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaires: state.questionnaires,
  projectId: ownProps.params.projectId,
  survey: state.surveys[ownProps.params.surveyId]
})

export default withRouter(connect(mapStateToProps)(SurveyWizardQuestionnaireStep))
