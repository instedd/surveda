// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepNumericEditor from './StepNumericEditor'
import DraggableStep from './DraggableStep'
import StepDeleteButton from './StepDeleteButton'
import StepStoreVariable from './StepStoreVariable'

type Props = {
  step: Step,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  project: any,
  errors: any,
  errorPath: string,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string,
  stepStore: string
};

class NumericStepEditor extends Component {
  props: Props
  state: State
  clickedVarAutocomplete: boolean

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
    this.clickedVarAutocomplete = false
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props
    const lang = props.questionnaire.defaultLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: (step.prompt[lang] || {}).sms || '',
      stepPromptIvr: ((step.prompt[lang] || {}).ivr || {}).text || '',
      stepStore: step.store || ''
    }
  }

  clickedVarAutocompleteCallback(e) {
    this.clickedVarAutocomplete = true
  }

  render() {
    const { step, onCollapse, questionnaire, stepsAfter, stepsBefore, onDelete } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let editor =
      <StepNumericEditor
        questionnaire={questionnaire}
        step={step}
        stepsAfter={stepsAfter}
        stepsBefore={stepsBefore} />

    let prompts = <StepPrompts stepPrompt={step.prompt[this.props.questionnaire.defaultLanguage]} stepId={step.id} sms={sms} ivr={ivr} />

    let optionsEditor = <li className='collection-item' key='editor'>
      <div className='row'>
        <div className='col s12'>
          {editor}
        </div>
      </div>
    </li>

    let variableName = <StepStoreVariable step={step} />

    let deleteButton = <StepDeleteButton onDelete={onDelete} />

    let icon = <StepTypeSelector stepType={step.type} stepId={step.id} />

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} icon={icon} stepId={step.id} stepTitle={this.state.stepTitle} >
          {prompts}
          {optionsEditor}
          {variableName}
          {deleteButton}
        </StepCard>
      </DraggableStep>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  project: state.project.data,
  questionnaire: state.questionnaire.data,
  errors: state.questionnaire.errors
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(NumericStepEditor)
