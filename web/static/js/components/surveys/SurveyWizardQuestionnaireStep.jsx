import React, { PropTypes, Component } from 'react'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import * as routes from '../../routes'
import { UntitledIfEmpty } from '../ui'

class SurveyWizardQuestionnaireStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    projectId: PropTypes.any.isRequired,
    dispatch: PropTypes.func.isRequired,
    router: PropTypes.object,
    readOnly: PropTypes.bool.isRequired
  }

  questionnaireChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaire(e.target.value))
  }

  createQuestionnaire(e) {
    e.preventDefault()

    // Prevent multiple clicks to create multiple questionnaires
    if (this.creatingQuestionnaire) return
    this.creatingQuestionnaire = true

    const { router, projectId, dispatch } = this.props

    dispatch(questionnaireActions.createQuestionnaire(projectId))
    .then(questionnaire => {
      this.creatingQuestionnaire = false
      router.push(routes.questionnaire(projectId, questionnaire.id))
    })
  }

  newQuestionnaireButton(projectId, questionnaires) {
    let buttonLabel = 'NEW QUESTIONNAIRE'
    if (Object.keys(questionnaires).length == 0) {
      buttonLabel = 'Create a questionnaire'
    }

    return (
      <div className='col s12'>
        <a className='waves-effect waves-teal btn-flat btn-flat-link' href='#' onClick={e => this.createQuestionnaire(e)}>
          {buttonLabel}
        </a>
      </div>
    )
  }

  questionnaireComparisonChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaireComparison())
  }

  render() {
    const { questionnaires, projectId, survey, readOnly } = this.props

    const questionnaireIds = survey.questionnaireIds || []
    const questionnaireComparison = (questionnaireIds.length > 1) ? true : (!!survey.questionnaireComparison)
    const inputType = questionnaireComparison ? 'checkbox' : 'radio'

    let newQuestionnaireComponent = null
    if (!readOnly) {
      newQuestionnaireComponent =
        this.newQuestionnaireButton(projectId, questionnaires)
    }

    return (
      <div>
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
            <p>
              <input
                id='questionnaires_comparison'
                type='checkbox'
                checked={questionnaireComparison}
                onChange={e => this.questionnaireComparisonChange(e)}
                className='filled-in'
                disabled={readOnly}
                />
              <label htmlFor='questionnaires_comparison'>Run a comparison with different questionnaires (you can setup the allocations later in the Comparisons section)</label>
            </p>
          </div>
          <div className='col s12 survey-questionnaires'>
            { Object.keys(questionnaires).map((questionnaireId) => {
              const questionnaire = questionnaires[questionnaireId]
              const className = questionnaire.valid ? null : 'tooltip-error'
              return (
                <div key={questionnaireId}>
                  <p>
                    <input
                      id={questionnaireId}
                      type={inputType}
                      name='questionnaire'
                      className={questionnaireComparison ? 'filled-in' : 'with-gap'}
                      value={questionnaireId}
                      checked={questionnaireIds.indexOf(parseInt(questionnaireId)) != -1}
                      onChange={e => this.questionnaireChange(e)}
                      disabled={readOnly}
                    />
                    <label htmlFor={questionnaireId}><UntitledIfEmpty text={questionnaires[questionnaireId].name} entityName='questionnaire' className={className} /></label>
                  </p>
                </div>
              )
            })}
          </div>
          {newQuestionnaireComponent}
        </div>
      </div>
    )
  }
}

export default withRouter(connect()(SurveyWizardQuestionnaireStep))
