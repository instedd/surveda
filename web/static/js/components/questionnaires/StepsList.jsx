import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

class StepsList extends Component {
  render() {
    const { steps, errorPath, onClick, readOnly, quotaCompletedSteps } = this.props
    if (steps.length != 0) {
      return (
        <ul className='collapsible'>
          { steps.map((step, index) => (
            <li key={step.id}>
              <QuestionnaireClosedStep
                step={step}
                stepIndex={index}
                errorPath={`${errorPath}[${index}]`}
                onClick={stepId => onClick(stepId)}
                readOnly={readOnly}
                quotaCompletedSteps={quotaCompletedSteps}
              />
            </li>
          ))}
        </ul>
      )
    } else {
      return null
    }
  }
}

StepsList.propTypes = {
  steps: PropTypes.array,
  errorPath: PropTypes.string,
  onClick: PropTypes.func,
  readOnly: PropTypes.bool,
  quotaCompletedSteps: PropTypes.bool
}

export default StepsList
