// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepDeleteButton from './StepDeleteButton'
import SkipLogic from './SkipLogic'
import propsAreEqual from '../../propsAreEqual'
import { translate } from 'react-i18next'

type Props = {
  step: ExplanationStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  stepsAfter: Step[],
  stepsBefore: Step[],
  t: Function,
  isNew: boolean
};

type State = {
  stepTitle: string,
  skipLogic: ?string
};

class ExplanationStepEditor extends Component {
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
      stepTitle: step.title,
      skipLogic: step.skipLogic
    }
  }

  skipLogicChange(skipOption, rangeIndex) {
    const { questionnaireActions, step } = this.props

    this.setState({ skipLogic: skipOption }, () => {
      questionnaireActions.changeExplanationStepSkipLogic(step.id, skipOption)
    })
  }

  render() {
    const { step, stepIndex, onCollapse, stepsAfter, stepsBefore, onDelete, errorPath, errorsByPath, isNew, readOnly, quotaCompletedSteps, t } = this.props

    return (
      <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle} icon={<StepTypeSelector stepType={step.type} stepId={step.id} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />} >
        <StepPrompts
          step={step}
          readOnly={readOnly}
          stepIndex={stepIndex}
          errorPath={errorPath}
          errorsByPath={errorsByPath}
          isNew={isNew}
          classes='no-separator'
          title={t('Message')}
        />
        <li className='collection-item' key='editor'>
          <div className='row'>
            <div className='col s6'>
              <SkipLogic
                onChange={skipOption => this.skipLogicChange(skipOption)}
                readOnly={readOnly}
                value={step.skipLogic}
                stepsAfter={stepsAfter}
                stepsBefore={stepsBefore}
                label={t('Skip logic')}
              />
            </div>
          </div>
        </li>
        {readOnly ? null : <StepDeleteButton onDelete={onDelete} /> }
      </StepCard>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default translate()(connect(null, mapDispatchToProps)(ExplanationStepEditor))
