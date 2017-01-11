// @flow
import React, { Component } from 'react'
import StepEditor from './StepEditor'
import StepsList from './StepsList'
import { DragDropContext } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'
import DraggableStep from './DraggableStep'

type Props = {
  steps: Step[],
  current: ?string,
  currentStepIsNew: boolean,
  readOnly: boolean,
  onSelectStep: Function,
  onDeselectStep: Function,
  onDeleteStep: Function,
  readOnly: boolean
};

const dummyDropTarget = (steps, readOnly) => {
  if (steps && steps.length > 0 && steps[0].type != 'language-selection') {
    return (
      <DraggableStep step={null} readOnly={readOnly}>
        <div style={{borderBottom: 'solid transparent'}} />
      </DraggableStep>
    )
  }

  return <div />
}

const questionnaireSteps = (steps, current, currentStepIsNew, onSelectStep, onDeselectStep, onDeleteStep, readOnly) => {
  if (current == null) {
    // All collapsed
    return <StepsList steps={steps} onClick={stepId => onSelectStep(stepId)} readOnly={readOnly} />
  } else {
    const itemIndex = steps.findIndex(step => step.id == current)

    // Only one expanded
    const stepsBefore = steps.slice(0, itemIndex)
    const currentStep = steps[itemIndex]
    const stepsAfter = steps.slice(itemIndex + 1)

    return (
      <div>
        <StepsList steps={stepsBefore} onClick={stepId => onSelectStep(stepId)} readOnly={readOnly} />
        <StepEditor
          step={currentStep}
          readOnly={readOnly}
          stepIndex={itemIndex}
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

class QuestionnaireSteps extends Component {
  props: Props

  render() {
    const { steps, current, currentStepIsNew, onSelectStep, onDeselectStep, onDeleteStep, readOnly } = this.props

    return (
      <div>
        {dummyDropTarget(steps, readOnly)}
        {questionnaireSteps(steps, current, currentStepIsNew, onSelectStep, onDeselectStep, onDeleteStep, readOnly)}
      </div>
    )
  }
}

export default DragDropContext(HTML5Backend)(QuestionnaireSteps)
