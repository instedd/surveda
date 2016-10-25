import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { Input } from 'react-materialize'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as projectActions from '../../actions/project'
import * as questionnairesActions from '../../actions/questionnaires'
import * as questionnaireActions from '../../actions/questionnaire'
import QuestionnaireSteps from './QuestionnaireSteps'

class QuestionnaireEditor extends Component {
  constructor(props) {
    super(props)

    this.state = this.internalState(null)
  }

  selectStep(stepId) {
    this.setState(this.internalState(stepId))
  }

  questionnaireNameSubmit(event) {
    event.preventDefault()
    this.props.questionnaireActions.changeName(event.target.value)
  }

  deselectStep() {
    this.setState(this.internalState(null))
  }

  questionnaireModesChange(event) {
    this.props.questionnaireActions.changeModes(event.target.value)
  }

  questionnaireSave(event) {
    event.preventDefault()
    this.props.questionnaireActions.save(this.props.questionnaire)
  }

  questionnaireAddMultipleChoiceStep() {
    this.questionnaireAddStep('multiple-choice')
  }

  questionnaireAddNumericStep() {
    this.questionnaireAddStep('numeric')
  }

  questionnaireAddStep(stepType) {
    this.setState({
      ...this.state,
      addingStep: true
    }, () => {
      // Add the step then automatically expand it
      this.props.questionnaireActions.addStep(stepType)
    })
  }

  deleteStep() {
    const currentStepId = this.state.currentStep

    this.setState({
      currentStep: null,
      addingStep: false
    }, () => {
      this.props.questionnaireActions.deleteStep(currentStepId)
    })
  }

  internalState(currentStep, addingStep = false) {
    return {
      currentStep,
      addingStep
    }
  }

  componentWillReceiveProps(newProps) {
    // This feels a bit hacky, but it let's us expand the step we just created.
    // I couldn't find a better way. Ideally this should be a sort of "callback"
    // to the addStep method, without involving additional component state handling
    // or explicit management via Redux reducers.
    const questionnaireData = newProps.questionnaire.data
    if (this.state.addingStep && questionnaireData != null && questionnaireData.steps != null && questionnaireData.steps.length > 0) {
      const newStep = questionnaireData.steps[questionnaireData.steps.length - 1]
      if (newStep != null) {
        this.setState(this.internalState(newStep.id))
      }
    }
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId) {
      if (questionnaireId) {
        this.props.projectActions.fetchProject(projectId)
        this.props.questionnaireActions.fetch(projectId, questionnaireId)

        this.props.questionnairesActions.fetchQuestionnaire(projectId, questionnaireId)
          .then((questionnaire) => {
            this.props.questionnaireActions.receive(questionnaire[0])
          })
      } else {
        this.props.questionnaireActions.newQuestionnaire(projectId)
      }
    }
  }

  render() {
    const { questionnaire } = this.props

    if (questionnaire.data == null) {
      return <div>Loading...</div>
    }

    return (
      <div className='row'>
        <div className='row'>
          <div className='col s12 m4'>
            <div className='row'>
              <Input s={12} type='select' label='Modes'
                value={questionnaire.data.modes.join(',')}
                onChange={e => this.questionnaireModesChange(e)}>
                <option value='SMS'>SMS</option>
              </Input>
            </div>
            <div className='row'>
              <button
                type='button'
                className='btn waves-effect waves-light'
                onClick={e => this.questionnaireSave(e)}>
              Save
              </button>
            </div>
          </div>
          <div className='col s12 m7 offset-m1'>
            <QuestionnaireSteps
              steps={questionnaire.data.steps}
              current={this.state.currentStep}
              onSelectStep={stepId => this.selectStep(stepId)}
              onDeselectStep={() => this.deselectStep()}
              onDeleteStep={() => this.deleteStep()} />
            <div className='row'>
              <div className='col s12 m6 center-align'>
                <a href='#!' className='btn-flat blue-text' onClick={() => this.questionnaireAddMultipleChoiceStep()}>Add multiple-choice step</a>
              </div>
              <div className='col s12 m6 center-align'>
                <a href='#!' className='btn-flat blue-text' onClick={() => this.questionnaireAddNumericStep()}>Add numeric step</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  projectActions: PropTypes.object.isRequired,
  questionnairesActions: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.object.isRequired,
  router: PropTypes.object,
  projectId: PropTypes.number,
  questionnaireId: PropTypes.string,
  questionnaire: PropTypes.object.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: ownProps.params.questionnaireId,
  questionnaire: state.questionnaire
})

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  questionnairesActions: bindActionCreators(questionnairesActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
