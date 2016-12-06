import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as projectActions from '../../actions/project'
import * as questionnaireActions from '../../actions/questionnaire'
import { csvForTranslation } from '../../reducers/questionnaire'
import QuestionnaireSteps from './QuestionnaireSteps'
import LanguagesList from '../questionnaires/LanguagesList'
import csvString from 'csv-string';

class QuestionnaireEditor extends Component {
  constructor(props) {
    super(props)
    this.state = this.internalState(null)
  }

  selectStep(stepId) {
    this.setState(this.internalState(stepId))
  }

  deselectStep() {
    this.setState(this.internalState(null))
  }

  toggleMode(event, mode) {
    this.props.questionnaireActions.toggleMode(mode)
  }

  questionnaireAddMultipleChoiceStep(e) {
    e.preventDefault()
    this.questionnaireAddStep('multiple-choice')
  }

  questionnaireAddNumericStep(e) {
    this.questionnaireAddStep('numeric')
  }

  questionnaireAddStep(e) {
    e.preventDefault()
    this.setState({
      ...this.state,
      addingStep: true
    }, () => {
      // Add the step then automatically expand it
      this.props.questionnaireActions.addStep()
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
    const questionnaireData = newProps.questionnaire
    if (this.state.addingStep && questionnaireData && questionnaireData.steps != null && questionnaireData.steps.length > 0) {
      const newStep = questionnaireData.steps[questionnaireData.steps.length - 1]
      if (newStep != null) {
        this.setState(this.internalState(newStep.id))
      }
    }
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      this.props.projectActions.fetchProject(projectId)
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
    }
  }

  downloadCsv(e) {
    e.preventDefault()

    const { questionnaire } = this.props

    const data = csvForTranslation(questionnaire)
    let csvContent = 'data:text/csv;charset=utf-8,'
    csvContent += csvString.stringify(data)
    const encodedUri = encodeURI(csvContent)
    window.location = encodedUri
  }

  render() {
    const { questionnaire } = this.props

    if (questionnaire == null) {
      return <div>Loading...</div>
    }

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    return (
      <div className='row'>
        <div className='col s12 m3 questionnaire-modes'>
          <div className='row'>
            <LanguagesList />
          </div>
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>file_download</i>
              <a href='#' onClick={e => this.downloadCsv(e)} download={`${questionnaire.name}.csv`}>Download contents as CSV</a>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <p className='grey-text'>Modes</p>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>sms</i>
              <span className='mode-label'>SMS</span>
              <div className='switch right'>
                <label>
                  <input type='checkbox' defaultChecked={sms} onClick={e => this.toggleMode(e, 'sms')} />
                  <span className='lever' />
                </label>
              </div>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>phone</i>
              <span className='mode-label'>Phone call</span>
              <div className='switch right'>
                <label>
                  <input type='checkbox' defaultChecked={ivr} onClick={e => this.toggleMode(e, 'ivr')} />
                  <span className='lever' />
                </label>
              </div>
            </div>
          </div>
        </div>
        <div className='col s12 m8 offset-m1'>
          <QuestionnaireSteps
            steps={questionnaire.steps}
            current={this.state.currentStep}
            onSelectStep={stepId => this.selectStep(stepId)}
            onDeselectStep={() => this.deselectStep()}
            onDeleteStep={() => this.deleteStep()} />
          <div className='row'>
            <div className='col s12'>
              <a href='#!' className='btn-flat blue-text no-padd' onClick={e => this.questionnaireAddStep(e)}>Add Step</a>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  projectActions: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.object.isRequired,
  router: PropTypes.object,
  projectId: PropTypes.any,
  questionnaireId: PropTypes.any,
  questionnaire: PropTypes.object
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
