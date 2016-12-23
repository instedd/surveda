// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
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
  stepPromptIvr: string
};

class MultipleChoiceStepEditor extends Component {
  props: Props
  state: State
  clickedVarAutocomplete: boolean

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
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
      stepPromptIvr: ((step.prompt[lang] || {}).ivr || {}).text || ''
    }
  }

  render() {
    const { step, onCollapse, questionnaire, errors, errorPath, stepsAfter, stepsBefore, onDelete } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} stepId={step.id} stepTitle={this.state.stepTitle}
          icon={
            <StepTypeSelector stepType={step.type} stepId={step.id} />
          } >
          <StepPrompts stepPrompt={step.prompt[this.props.questionnaire.defaultLanguage]} stepId={step.id} sms={sms} ivr={ivr} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepMultipleChoiceEditor
                  questionnaire={questionnaire}
                  step={step}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore}
                  sms={sms}
                  ivr={ivr}
                  errors={errors}
                  errorPath={errorPath} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} />
          <StepDeleteButton onDelete={onDelete} />
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

export default connect(mapStateToProps, mapDispatchToProps)(MultipleChoiceStepEditor)
