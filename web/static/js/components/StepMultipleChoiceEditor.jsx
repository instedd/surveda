import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Card from './Card'

class StepMultipleChoiceEditor extends Component {
  render () {
    const { step } = this.props
    const { choices } = step
    return (
      <Card>
        <table>
          <thead>
            <tr>
              <th>Response</th>
              <th>SMS</th>
            </tr>
          </thead>
          <tbody>
            { choices.map((choice, index) =>
              <tr key={index}>
                <td>
                  {choice.value}
                </td>
                <td>
                  {choice.responses.join(", ")}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    )
  }
}

StepMultipleChoiceEditor.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(StepMultipleChoiceEditor)
