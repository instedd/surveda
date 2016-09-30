import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import Card from '../components/Card'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'
import StepEditor from './StepEditor'

const renderSteps = (steps) => {
  if (steps.length != 0) {
    return (
      <Card>
        <ul className="collection">
          { steps.map((step) => (
            <QuestionnaireClosedStep step={step} key={step.id} />
          ))}
        </ul>
      </Card>
    )
  } else {
    return null
  }
}

const renderCurrentStep = (step) => (
  <StepEditor step={step} />
)

const QuestionnaireSteps = ({ steps, currentStepId }) => {
  if (steps) {
    const index = steps.findIndex(step => step.id == currentStepId)
    if (index == -1) {
      // All collapsed
      return renderSteps(steps)
    } else {
      // Only one expanded
      const stepsBefore = steps.slice(0, index)
      const currentStep = steps[index]
      const stepsAfter = steps.slice(index + 1)

      return (
        <div>
        {renderSteps(stepsBefore)}
        {renderCurrentStep(currentStep)}
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
  steps: PropTypes.array,
}

export default QuestionnaireSteps
