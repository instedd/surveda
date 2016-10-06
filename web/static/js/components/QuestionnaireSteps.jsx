import React, { PropTypes } from 'react'
import Card from '../components/Card'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'
import StepEditor from './StepEditor'

const renderSteps = (steps) => {
  if (steps.length !== 0) {
    return (
      <Card>
        <ul className='collection'>
          { steps.map((step) => (
            <QuestionnaireClosedStep step={step} key={step.title} />
          ))}
        </ul>
      </Card>
    )
  } else {
    return null
  }
}

const QuestionnaireSteps = ({ questionnaireEditor }) => {
  if (questionnaireEditor.steps) {
    var steps = questionnaireEditor.steps
    if (!questionnaireEditor.currentStepId) {
      // All collapsed
      return renderSteps(steps.ids.map((id) => steps.items[id]))
    } else {
      const index = steps.ids.findIndex(stepId => stepId === questionnaireEditor.currentStepId)

      // Only one expanded
      const stepsBefore = steps.ids.slice(0, index).map((id) => steps.items[id])
      const currentStep = steps.items[questionnaireEditor.currentStepId]
      const stepsAfter = steps.ids.slice(index + 1).map((id) => steps.items[id])

      return (
        <div>
          {renderSteps(stepsBefore)}
          <StepEditor step={currentStep} />
          {renderSteps(stepsAfter)}
        </div>
      )
    }
  } else {
    return (
      <div>
        Sorry! There are no steps here and there's no way to create them yet. It's a bit embarrasing, but the Ask team is working really hard on that feature. In the meantime, if you save this questionnaire we'll create two steps for you to play around.
      </div>
    )
  }
}

QuestionnaireSteps.propTypes = {
  steps: PropTypes.object,
  currentStepId: PropTypes.string
}

export default QuestionnaireSteps
