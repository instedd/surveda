import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import Card from '../components/Card'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

const renderSteps = (steps) => {
  if (steps.length != 0) {
    return (
      <div className="card white">
        <ul className="collection">
          { steps.map((step) => (
            <QuestionnaireClosedStep step={step} key={step.id} />
          ))}
        </ul>
      </div>
    )
  } else {
    return null
  }
}

const QuestionnaireSteps = ({ steps, currentStepId }) => {
  const index = steps.findIndex(step => step.id == currentStepId)
  if (index == -1) {
    // All collapsed
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
    // Only one expanded
    const stepsBefore = steps.slice(0, index)
    const currentStep = steps[index]
    const stepsAfter = steps.slice(index + 1)

    return (
      <div>
        {renderSteps(stepsBefore)}
        <Card>
          <ul className="collection">
            <li className="collection-item">{currentStep.title}</li>
          </ul>
        </Card>
        {renderSteps(stepsAfter)}
      </div>
    )
  }
}

QuestionnaireSteps.propTypes = {
  steps: PropTypes.array.isRequired,
}

export default QuestionnaireSteps
