import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { Input } from 'react-materialize'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { createQuestionnaire, updateQuestionnaire } from '../../api'
import * as projectActions from '../../actions/project'
import * as questionnaireActions from '../../actions/questionnaires'
import * as actions from '../../actions/questionnaireEditor'
import { questionnaireForServer } from '../../reducers/questionnaireEditor'
import QuestionnaireSteps from './QuestionnaireSteps'

class QuestionnaireEditor extends Component {
  constructor(props) {
    super(props)
    this.state = { questionnaireName: '' }
  }

  questionnaireNameChange(event) {
    event.preventDefault()
    this.setState({questionnaireName: event.target.value})
  }

  questionnaireNameSubmit(event) {
    event.preventDefault()
    this.props.actions.changeQuestionnaireName(event.target.value)
  }

  toggleMode(event, mode) {
    this.props.actions.toggleQuestionnaireMode(mode)
  }

  questionnaireSave(event) {
    event.preventDefault()
    const { questionnaireEditor } = this.props

    const questionnaire = questionnaireForServer(questionnaireEditor)

    if (questionnaire.id == null) {
      createQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => this.props.questionnaireActions.createQuestionnaire(questionnaire))
    } else {
      updateQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => this.props.questionnaireActions.updateQuestionnaire(questionnaire))
    }
  }

  questionnaireAddMultipleChoiceStep() {
    this.questionnaireAddStep('multiple-choice')
  }

  questionnaireAddNumericStep() {
    this.questionnaireAddStep('numeric')
  }

  questionnaireAddStep(stepType) {
    this.props.actions.addStep(stepType)
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId) {
      if (questionnaireId) {
        this.props.projectActions.fetchProject(projectId)

        this.props.questionnaireActions.fetchQuestionnaire(projectId, questionnaireId)
          .then((items) => {
            let questionnaire
            for (const id in items) {
              questionnaire = items[id]
              break
            }
            // TODO: Fix this, or decide how to make it better
            this.props.actions.initializeEditor(questionnaire)
          })
      } else {
        this.props.actions.newQuestionnaire(projectId)
      }
    }
  }

  componentWillReceiveProps(newProps) {
    const { questionnaireEditor } = newProps
    if (questionnaireEditor.questionnaire) {
      this.setState({questionnaireName: questionnaireEditor.questionnaire.name})
    }
  }

  render() {
    const { questionnaireEditor } = this.props

    if (!questionnaireEditor.questionnaire) {
      return <div>Loading...</div>
    }

    const questionnaire = questionnaireEditor.questionnaire
    const sms = questionnaire.modes.indexOf('SMS') != -1
    const ivr = questionnaire.modes.indexOf('IVR') != -1

    return (
      <div className='row'>
        <div className='row'>
          <div className='col s12 m4'>
            <div className='input-field col s12'>
              <input
                type='text'
                id='questionnaire_name'
                placeholder='Untitled'
                value={this.state.questionnaireName}
                onChange={e => this.questionnaireNameChange(e)}
                onBlur={e => this.questionnaireNameSubmit(e)}
                />
              <label className='active' htmlFor='questionnaire_name'>Questionnaire Name</label>
            </div>
            <div className='row'>
              <button type='button' className={`btn-floating btn-flat btn-large waves-effect waves-light ${sms ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`}
                onClick={e => this.toggleMode(e, 'SMS')}>SMS</button>
              <button type='button' className={`btn-floating btn-flat btn-large waves-effect waves-light ${ivr ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`}
                onClick={e => this.toggleMode(e, 'IVR')}>IVR</button>
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
            <QuestionnaireSteps steps={questionnaireEditor.steps} />
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
  actions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.object.isRequired,
  router: PropTypes.object,
  projectId: PropTypes.number,
  questionnaireId: PropTypes.string,
  questionnaireEditor: PropTypes.object.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: ownProps.params.questionnaireId,
  questionnaireEditor: state.questionnaireEditor
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
