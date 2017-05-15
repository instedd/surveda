// @flow
import React, { Component } from 'react'
import StepEditor from './StepEditor'
import StepsList from './StepsList'
import { DragDropContext } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'
import DraggableStep from './DraggableStep'

type State = {
  currentStepId: ?string,
  currentStepIsNew: boolean
};

type Props = {
  steps: Step[],
  errorPath: string,
  errorsByPath: ErrorsByPath,
  readOnly: boolean,
  onSelectStep: Function,
  onDeselectStep: Function,
  onDeleteStep: Function,
  readOnly: boolean,
  quotaCompletedSteps?: boolean
};

class QuestionnaireSteps extends Component {
  props: Props
  state: State
  selectStep: Function
  deselectStep: Function
  deleteStep: Function

  constructor(props) {
    super(props)
    this.selectStep = this.selectStep.bind(this)
    this.deselectStep = this.deselectStep.bind(this)
    this.deleteStep = this.deleteStep.bind(this)

    this.state = {
      currentStepId: null,
      currentStepIsNew: false
    }
  }

  getCurrentStepId() {
    return this.state.currentStepId
  }

  selectStep(stepId, isNew = false) {
    this.setState({
      currentStepId: stepId,
      currentStepIsNew: isNew
    })
  }

  deselectStep(callback) {
    this.setState({
      currentStepId: null,
      currentStepIsNew: false
    }, callback || (() => {}))
  }

  deleteStep() {
    const { onDeleteStep } = this.props

    const currentStepId = this.state.currentStepId
    this.setState({currentStepId: null}, () => {
      onDeleteStep(currentStepId)
    })
  }

  dummyDropTarget() {
    const { steps, readOnly, quotaCompletedSteps } = this.props

    if (steps && steps.length > 0 && steps[0].type != 'language-selection') {
      return (
        <DraggableStep step={null} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps}>
          <div style={{borderBottom: 'solid transparent'}} />
        </DraggableStep>
      )
    }

    return <div />
  }

  questionnaireSteps() {
    const { steps, errorPath, errorsByPath, readOnly, quotaCompletedSteps } = this.props
    const current = this.state.currentStepId
    const currentStepIsNew = this.state.currentStepIsNew

    if (current == null) {
      // All collapsed
      return <StepsList steps={steps} errorPath={errorPath} onClick={this.selectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
    } else {
      const itemIndex = steps.findIndex(step => step.id == current)

      // Only one expanded
      const stepsBefore = steps.slice(0, itemIndex)
      const currentStep = steps[itemIndex]
      const stepsAfter = steps.slice(itemIndex + 1)

      return (
        <div>
          <StepsList steps={stepsBefore} errorPath={errorPath} onClick={this.selectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
          <StepEditor
            step={currentStep}
            stepIndex={itemIndex}
            errorPath={`${errorPath}[${itemIndex}]`}
            errorsByPath={errorsByPath}
            readOnly={readOnly}
            quotaCompletedSteps={!!quotaCompletedSteps}
            isNew={currentStepIsNew}
            onCollapse={this.deselectStep}
            onDelete={this.deleteStep}
            stepsAfter={stepsAfter}
            stepsBefore={stepsBefore} />
          <StepsList steps={stepsAfter} onClick={this.selectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
        </div>
      )
    }
  }

  render() {
    return (
      <div>
        {this.dummyDropTarget()}
        {this.questionnaireSteps()}
      </div>
    )
  }
}

export default DragDropContext(HTML5Backend)(QuestionnaireSteps)
