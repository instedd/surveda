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
  current: ?string,
  currentStepIsNew: boolean,
  readOnly: boolean,
  onSelectStep: Function,
  onDeselectStep: Function,
  onDeleteStep: Function,
  readOnly: boolean
};

class QuestionnaireSteps extends Component {
  props: Props

  dummyDropTarget() {
    const { steps, readOnly } = this.props

    if (steps && steps.length > 0 && steps[0].type != 'language-selection') {
      return (
        <DraggableStep step={null} readOnly={readOnly}>
          <div style={{borderBottom: 'solid transparent'}} />
        </DraggableStep>
      )
    }

    return <div />
  }

  questionnaireSteps() {
    const { steps, errorPath, errorsByPath, current, currentStepIsNew, onSelectStep, onDeselectStep, onDeleteStep, readOnly } = this.props

    if (current == null) {
      // All collapsed
      return <StepsList steps={steps} errorPath={errorPath} onClick={stepId => onSelectStep(stepId)} readOnly={readOnly} />
    } else {
      const itemIndex = steps.findIndex(step => step.id == current)

      // Only one expanded
      const stepsBefore = steps.slice(0, itemIndex)
      const currentStep = steps[itemIndex]
      const stepsAfter = steps.slice(itemIndex + 1)

      return (
        <div>
          <StepsList steps={stepsBefore} errorPath={errorPath} onClick={stepId => onSelectStep(stepId)} readOnly={readOnly} />
          <StepEditor
            step={currentStep}
            stepIndex={itemIndex}
            errorPath={`${errorPath}[${itemIndex}]`}
            errorsByPath={errorsByPath}
            readOnly={readOnly}
            isNew={currentStepIsNew}
            onCollapse={() => onDeselectStep()}
            onDelete={() => onDeleteStep()}
            stepsAfter={stepsAfter}
            stepsBefore={stepsBefore} />
          <StepsList steps={stepsAfter} onClick={stepId => onSelectStep(stepId)} readOnly={readOnly} />
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
