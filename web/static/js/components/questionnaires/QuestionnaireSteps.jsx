import React, { PropTypes } from 'react'
import { Card } from '../ui'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'
import StepEditor from './StepEditor'

const StepsList = ({steps, onClick}) => {
  if (steps.length != 0) {
    return (
      <div>
        { steps.map((step) => (
          <Card key={step.id} >
            <div className='card-content closed-step'>
              <QuestionnaireClosedStep step={step} onClick={stepId => onClick(stepId)} />
            </div>
          </Card>
        ))}
      </div>
    )
  } else {
    return null
  }
}

const QuestionnaireSteps = ({ steps, current, onSelectStep, onDeselectStep, onDeleteStep }) => {
  if (current == null) {
    // All collapsed
    return <StepsList steps={steps} onClick={stepId => onSelectStep(stepId)} />
  } else {
    const itemIndex = steps.findIndex(step => step.id == current)

    // Only one expanded
    const stepsBefore = steps.slice(0, itemIndex)
    const currentStep = steps[itemIndex]
    const stepsAfter = steps.slice(itemIndex + 1)

    return (
      <div>
        <StepsList steps={stepsBefore} onClick={stepId => onSelectStep(stepId)} />
        <StepEditor
          step={currentStep}
          onCollapse={() => onDeselectStep()}
          onDelete={() => onDeleteStep()}
          skip={stepsAfter} />
        <StepsList steps={stepsAfter} onClick={stepId => onSelectStep(stepId)} />
      </div>
    )
  }
}

QuestionnaireSteps.propTypes = {
  steps: PropTypes.array.isRequired,
  current: PropTypes.string,
  onSelectStep: PropTypes.func.isRequired,
  onDeselectStep: PropTypes.func.isRequired,
  onDeleteStep: PropTypes.func.isRequired
}

StepsList.propTypes = {
  steps: PropTypes.array,
  onClick: PropTypes.func
}

export default QuestionnaireSteps
