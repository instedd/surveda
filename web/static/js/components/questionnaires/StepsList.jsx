import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'
import Section from './Section'

class StepsList extends Component {
  render() {
    const { steps, errorPath, onClick, readOnly, quotaCompletedSteps } = this.props
    let { startIndex } = this.props
    if (startIndex == null) startIndex = 0

    if (steps.length != 0) {
      return (
        <Section>
          <ul className='collapsible'>
            { steps.map((step, index) => (
              <li key={step.id}>
                <QuestionnaireClosedStep
                  step={step}
                  stepIndex={startIndex + index}
                  errorPath={`${errorPath}[${startIndex + index}]`}
                  onClick={stepId => onClick(stepId)}
                  readOnly={readOnly}
                  quotaCompletedSteps={quotaCompletedSteps}
                />
              </li>
            ))}
          </ul>
        </Section>
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
  startIndex: PropTypes.number
}

export default StepsList
