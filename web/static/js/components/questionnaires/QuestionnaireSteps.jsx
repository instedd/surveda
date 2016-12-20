import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'
import StepEditor from './StepEditor'
import { DragDropContext } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'

const StepsList = ({steps, onClick}) => {
  if (steps.length != 0) {
    return (
      <ul className='collapsible'>
        { steps.map((step) => (
          <li key={step.id}>
            <QuestionnaireClosedStep step={step} onClick={stepId => onClick(stepId)} />
          </li>
        ))}
      </ul>
    )
  } else {
    return null
  }
}

class QuestionnaireSteps extends Component {
  render() {
    const { steps, current, onSelectStep, onDeselectStep, onDeleteStep } = this.props
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
            errorPath={`steps[${itemIndex}]`}
            onCollapse={() => onDeselectStep()}
            onDelete={() => onDeleteStep()}
            stepsAfter={stepsAfter} />
          <StepsList steps={stepsAfter} onClick={stepId => onSelectStep(stepId)} />
        </div>
      )
    }
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

export default DragDropContext(HTML5Backend)(QuestionnaireSteps)
