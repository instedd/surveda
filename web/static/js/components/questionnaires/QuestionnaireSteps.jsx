// @flow
import React, { Component } from 'react'
import StepEditor from './StepEditor'
import StepsList from './StepsList'
import { DragDropContext } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'
import DraggableStep from './DraggableStep'

type Props = {
  steps: Step[],
  errorPath: string,
  errorsByPath: ErrorsByPath,
  readOnly: boolean,
  onSelectStep: Function,
  onDeselectStep: Function,
  onDeleteStep: Function,
  readOnly: boolean,
  quotaCompletedSteps?: boolean,
  selectedSteps: Object
};

class QuestionnaireSteps extends Component {
  props: Props

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
    const { steps, errorPath, errorsByPath, readOnly, quotaCompletedSteps, selectedSteps, onSelectStep, onDeselectStep, onDeleteStep } = this.props
    const current = selectedSteps.currentStepId
    const currentStepIsNew = selectedSteps.currentStepIsNew
    const itemIndex = steps.findIndex(step => step.id == current)

    if (current == null || itemIndex < 0) {
      // All collapsed
      return <StepsList steps={steps} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
    } else {
      // Only one expanded
      const stepsBefore = steps.slice(0, itemIndex)
      const currentStep = steps[itemIndex]
      const stepsAfter = steps.slice(itemIndex + 1)

      return (
        <div>
          <StepsList steps={stepsBefore} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
          <StepEditor
            step={currentStep}
            stepIndex={itemIndex}
            errorPath={`${errorPath}[${itemIndex}]`}
            errorsByPath={errorsByPath}
            readOnly={readOnly}
            quotaCompletedSteps={!!quotaCompletedSteps}
            isNew={currentStepIsNew}
            onCollapse={onDeselectStep}
            onDelete={onDeleteStep}
            stepsAfter={stepsAfter}
            stepsBefore={stepsBefore} />
          <StepsList steps={stepsAfter} startIndex={itemIndex + 1} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} />
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
