// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepLanguageSelection from './StepLanguageSelection'
import DraggableStep from './DraggableStep'
import StepStoreVariable from './StepStoreVariable'
import propsAreEqual from '../../propsAreEqual'

type Props = {
  step: LanguageSelectionStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  readOnly: boolean,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  isNew: boolean
};

type State = {
  stepTitle: string
};

class LanguageSelectionStepEditor extends Component {
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
    const { step, stepIndex, onCollapse, errorPath, errorsByPath, isNew, readOnly } = this.props

    return (
      <DraggableStep step={step} readOnly={readOnly} quotaCompletedSteps={false}>
        <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle} icon={<i className='material-icons left'>language</i>} >
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
                <StepLanguageSelection step={step} readOnly={readOnly} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} readOnly={readOnly} errorPath={errorPath} errorsByPath={errorsByPath} />
        </StepCard>
      </DraggableStep>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(LanguageSelectionStepEditor)
