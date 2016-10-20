import React, { Component, PropTypes } from 'react'
import { Input } from 'react-materialize'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { createQuestionnaire, updateQuestionnaire } from '../../api'
import * as projectActions from '../../actions/projects'
import * as questionnaireActions from '../../actions/questionnaires'
import * as actions from '../../actions/questionnaireEditor'
import { questionnaireForServer } from '../../reducers/questionnaireEditor'
import QuestionnaireSteps from './QuestionnaireSteps'
import * as routes from '../../routes'

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
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaireName(event.target.value))
  }

  questionnaireModesChange(event) {
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaireModes(event.target.value))
  }

  questionnaireSave(event) {
    event.preventDefault()
    const { dispatch, questionnaireEditor, router } = this.props

    const questionnaire = questionnaireForServer(questionnaireEditor)

    if (questionnaire.id == null) {
      createQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.createQuestionnaire(questionnaire)))
        .then(() => router.push(routes.questionnaires(questionnaire.projectId)))
    } else {
      updateQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.updateQuestionnaire(questionnaire)))
        .then(() => router.push(routes.questionnaires(questionnaire.projectId)))
    }
  }

  questionnaireAddMultipleChoiceStep() {
    this.questionnaireAddStep('multiple-choice')
  }

  questionnaireAddNumericStep() {
    this.questionnaireAddStep('numeric')
  }

  questionnaireAddStep(stepType) {
    const { dispatch } = this.props
    dispatch(actions.addStep(stepType))
  }

  componentWillMount() {
    const { dispatch, projectId, questionnaireId } = this.props

    if (projectId) {
      if (questionnaireId) {
        dispatch(projectActions.fetchProject(projectId))

        dispatch(questionnaireActions.fetchQuestionnaire(projectId, questionnaireId))
          .then((questionnaire) => {
            // TODO: Fix this, or decide how to make it better
            var quest = questionnaire.response.entities.questionnaires[questionnaire.response.result]
            dispatch(actions.initializeEditor(quest))
          })
      } else {
        dispatch(actions.newQuestionnaire(projectId))
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
              <Input s={12} type='select' label='Modes'
                value={questionnaire.modes.join(',')}
                onChange={e => this.questionnaireModesChange(e)}>
                <option value='SMS'>SMS</option>
              </Input>
            </div>
          </div>
          <div className='col s12 m7 offset-m1'>
            <QuestionnaireSteps steps={questionnaireEditor.steps} />
            <div className='row'>
              <div className='col s12 m6 center-align'>
                <a href='#!' className="btn-flat blue-text" onClick={() => this.questionnaireAddMultipleChoiceStep()}>Add multiple-choice step</a>
              </div>
              <div className='col s12 m6 center-align'>
                <a href='#!' className="btn-flat blue-text" onClick={() => this.questionnaireAddNumericStep()}>Add numeric step</a>
              </div>
            </div>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <button
              type='button'
              className='btn waves-effect waves-light'
              onClick={e => this.questionnaireSave(e)}>
              Save
            </button>
          </div>
        </div>
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  dispatch: PropTypes.func,
  router: PropTypes.object,
  projectId: PropTypes.string,
  questionnaireId: PropTypes.string,
  questionnaireEditor: PropTypes.object.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaireEditor: state.questionnaireEditor
})

export default withRouter(connect(mapStateToProps)(QuestionnaireEditor))
