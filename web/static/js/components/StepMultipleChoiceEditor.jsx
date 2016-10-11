import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'
import Card from './Card'

class StepMultipleChoiceEditor extends Component {
  deleteChoice(e, index) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.deleteChoice(index))
  }

  render() {
    const { step } = this.props
    const { choices } = step
    return (
      <Card>
        <table>
          <thead>
            <tr>
              <th>Response</th>
              <th>SMS</th>
              <th />
            </tr>
          </thead>
          <tbody>
            { choices.map((choice, index) =>
              <tr key={index}>
                <td>
                  {choice.value}
                </td>
                <td>
                  {choice.responses.join(', ')}
                </td>
                <td>
                  <a href='#!' onClick={(e) => this.deleteChoice(e, index)}><i className='material-icons'>delete</i></a>
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
