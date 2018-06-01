import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

class StepsList extends Component {
  render() {
    const { steps, errorPath, onClick, readOnly, quotaCompletedSteps, increaseErrorIndex } = this.props
    let { startIndex } = this.props
    if (startIndex == null) startIndex = 0

    if (steps.length != 0) {
      return (
        <ul className='collapsible'>
          { steps.map((step, index) => {
            const errorIndex = increaseErrorIndex ? startIndex + index + 1 : startIndex + index
            return (
              <li key={step.id}>
                <QuestionnaireClosedStep
                  step={step}
                  stepIndex={startIndex + index}
                  errorPath={`${errorPath}[${errorIndex}]`}
                  onClick={stepId => onClick(stepId)}
                  readOnly={readOnly}
                  quotaCompletedSteps={quotaCompletedSteps}
                />
              </li>
            )
          })}
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
  quotaCompletedSteps: PropTypes.bool,
  startIndex: PropTypes.number,
  increaseErrorIndex: PropTypes.bool
}

export default StepsList
