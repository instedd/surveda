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
import { getStepPromptSms, getStepPromptIvrText } from '../../step'
import propsAreEqual from '../../propsAreEqual'

type Props = {
  step: MultipleChoiceStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  errorPath: string,
  errorsByPath: ErrorsByPath,
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

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step, questionnaire } = props
    const lang = questionnaire.activeLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: getStepPromptSms(step, lang),
      stepPromptIvr: getStepPromptIvrText(step, lang)
    }
  }

  render() {
    const { step, stepIndex, onCollapse, questionnaire, readOnly, quotaCompletedSteps, errorPath, errorsByPath, stepsAfter, stepsBefore, onDelete } = this.props

    return (
      <DraggableStep step={step} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps}>
        <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle}
          icon={
            <StepTypeSelector stepType={step.type} stepId={step.id} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
          } >
          <StepPrompts
            step={step}
            readOnly={readOnly}
            stepIndex={stepIndex}
            errorPath={errorPath}
            errorsByPath={errorsByPath} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepMultipleChoiceEditor
                  questionnaire={questionnaire}
                  step={step}
                  stepIndex={stepIndex}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore}
                  readOnly={readOnly}
                  errorPath={errorPath}
                  errorsByPath={errorsByPath} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} readOnly={readOnly} />
          {readOnly ? null : <StepDeleteButton onDelete={onDelete} /> }
        </StepCard>
      </DraggableStep>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(MultipleChoiceStepEditor)
