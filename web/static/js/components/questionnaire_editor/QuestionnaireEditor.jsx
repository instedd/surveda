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

class QuestionnaireEditor extends Component {
  constructor(props) {
    super(props)
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
        .then(() => router.push(`/projects/${questionnaire.projectId}/questionnaires`))
    } else {
      updateQuestionnaire(questionnaire.projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.updateQuestionnaire(questionnaire)))
        .then(() => router.push(`/projects/${questionnaire.projectId}/questionnaires`))
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
            <div className='row'>
              <Input s={12} type='select' label='Mode'
                value={questionnaire.modes.join(',')}
                onChange={e => this.questionnaireModesChange(e)}>
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
