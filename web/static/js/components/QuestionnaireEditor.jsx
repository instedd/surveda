import React, { Component, PropTypes } from 'react'
import { Input } from 'react-materialize'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { createQuestionnaire, updateQuestionnaire } from '../api'
import * as projectActions from '../actions/projects'
import * as questionnaireActions from '../actions/questionnaires'
import * as actions from '../actions/questionnaireEditor'
import QuestionnaireSteps from './QuestionnaireSteps'
import uuid from 'node-uuid'

class QuestionnaireEditor extends Component {
  constructor (props) {
    super(props)

    this.state = { questionnaireName: '' }

    this.questionnaireNameChange = this.questionnaireNameChange.bind(this)
    this.questionnaireNameSubmit = this.questionnaireNameSubmit.bind(this)

    this.questionnaireModesChange = this.questionnaireModesChange.bind(this)

    this.questionnaireSave = this.questionnaireSave.bind(this)
  }

  questionnaireModesChange (event) {
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaireModes(event.target.value))
  }

  questionnaireNameChange (event) {
    event.preventDefault()
    this.setState({questionnaireName: event.target.value})
  }

  questionnaireNameSubmit (event) {
    event.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.changeQuestionnaireName(event.target.value))
  }

  questionnaireSave (event) {
    event.preventDefault()
    const { dispatch, questionnaireEditor, router } = this.props

    const questionnaire = questionnaireEditor.questionnaire

    if (questionnaire.id == null) {
      createQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.createQuestionnaire(questionnaire)))
        .then(() => router.push(`/projects/${questionnaire.projectId}/questionnaires`))
    } else {
      updateQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.updateQuestionnaire(questionnaire)))
        .then(() => router.push(`/projects/${questionnaire.projectId}/questionnaires`))
    }
  }

  questionnaireAddMultipleChoiceStep () {
    this.questionnaireAddStep({
      id: uuid.v4(),
      type: 'multiple-choice',
      title: 'Untitled multiple-choice',
      choices: []
    })
  }

  questionnaireAddNumericStep () {
    this.questionnaireAddStep({
      id: uuid.v4(),
      type: 'numeric',
      title: 'Untitled numeric',
      choices: []
    })
  }

  questionnaireAddStep (step) {
    const { dispatch } = this.props
    dispatch(actions.addStep(step))
  }

  componentWillMount () {
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

  componentWillReceiveProps (newProps) {
    const { questionnaireEditor } = newProps
    if (questionnaireEditor.questionnaire) {
      this.setState({questionnaireName: questionnaireEditor.questionnaire.name})
    }
  }

  render () {
    const { questionnaireEditor } = this.props

    if (!questionnaireEditor.questionnaire) {
      return <div>Loading...</div>
    }

    const questionnaire = questionnaireEditor.questionnaire

    return (
      <div className='row'>
        <div className='row'>
          <div className='col s12 m4'>
            <div className='row'>
              <div className='input-field col s12'>
                <input
                  type='text'
                  id='questionnaire_name'
                  placeholder='Questionnaire name'
                  value={this.state.questionnaireName}
                  onChange={this.questionnaireNameChange}
                  onBlur={this.questionnaireNameSubmit}
                  />
                <label className='active' htmlFor='questionnaire_name'>Questionnaire Name</label>
              </div>
            </div>
            <div className='row'>
              <Input s={12} type='select' label='Mode'
                value={questionnaire.modes.join(',')}
                onChange={this.questionnaireModesChange}>
                <option value='SMS'>SMS</option>
                <option value='IVR'>IVR</option>
                <option value='SMS,IVR'>SMS and IVR</option>
              </Input>
            </div>
          </div>
          <div className='col s12 m8'>
            <QuestionnaireSteps steps={questionnaireEditor.steps} />
            <div className='row'>
              <div className='col s12'>
                <a href='#!' onClick={() => this.questionnaireAddMultipleChoiceStep()}>Add multiple-choice step</a>
                &nbsp; | &nbsp;
                <a href='#!' onClick={() => this.questionnaireAddNumericStep()}>Add numeric step</a>
              </div>
            </div>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <button
              type='button'
              className='btn waves-effect waves-light'
              onClick={this.questionnaireSave}>
              Submit
            </button>
          </div>
        </div>
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  questionnaireEditor: PropTypes.object.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaireEditor: state.questionnaireEditor
})

export default withRouter(connect(mapStateToProps)(QuestionnaireEditor))
