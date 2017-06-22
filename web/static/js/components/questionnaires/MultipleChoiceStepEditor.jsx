// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepDeleteButton from './StepDeleteButton'
import StepStoreVariable from './StepStoreVariable'
import propsAreEqual from '../../propsAreEqual'
import withQuestionnaire from './withQuestionnaire'

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
  stepsBefore: Step[],
  isNew: boolean
};

type State = {
  stepTitle: string
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
    const { step } = props

    return {
      stepTitle: step.title
    }
  }

  render() {
    const { step, stepIndex, onCollapse, questionnaire, readOnly, quotaCompletedSteps, errorPath, errorsByPath, stepsAfter, stepsBefore, onDelete, isNew } = this.props

    return (
      <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle}
        icon={
          <StepTypeSelector stepType={step.type} stepId={step.id} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
        } >
        <StepPrompts
          step={step}
          readOnly={readOnly}
          stepIndex={stepIndex}
          errorPath={errorPath}
          errorsByPath={errorsByPath}
          isNew={isNew}
          />
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
                errorsByPath={errorsByPath}
                isNew={isNew} />
            </div>
          </div>
        </li>
        <StepStoreVariable step={step} readOnly={readOnly} errorPath={errorPath} errorsByPath={errorsByPath} />
        {readOnly ? null : <StepDeleteButton onDelete={onDelete} /> }
      </StepCard>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(withQuestionnaire(MultipleChoiceStepEditor))
