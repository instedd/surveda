import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import { Link } from 'react-router'
import * as routes from '../../routes'
import { UntitledIfEmpty } from '../ui'

class SurveyWizardQuestionnaireStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    projectId: PropTypes.any.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  questionnaireChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaire(e.target.value))
  }

  newQuestionnaireButton(projectId, questionnaires) {
    let buttonLabel = 'NEW QUESTIONNAIRE'
    if (Object.keys(questionnaires).length == 0) {
      buttonLabel = "You still haven't created any questionnaire. Click here to create one."
    }

    return (
      <div className='col s12'>
        <Link className='waves-effect waves-teal btn-flat btn-flat-link' to={routes.newQuestionnaire(projectId)}>
          {buttonLabel}
        </Link>
      </div>
    )
  }

  render() {
    const { questionnaires, projectId } = this.props
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
            { Object.keys(questionnaires).map((questionnaireId) => (
              <div key={questionnaireId}>
                <p>
                  <input
                    id={questionnaireId}
                    type='radio'
                    name='questionnaire'
                    className='with-gap'
                    value={questionnaireId}
                    defaultChecked={this.props.survey.questionnaireId == questionnaireId}
                    onClick={e => this.questionnaireChange(e)}
                  />
                  <label htmlFor={questionnaireId}><UntitledIfEmpty text={questionnaires[questionnaireId].name} /></label>
                </p>
              </div>
            ))}
          </div>
          {this.newQuestionnaireButton(projectId, questionnaires)}
        </div>
      </div>
    )
  }
}

export default connect()(SurveyWizardQuestionnaireStep)
