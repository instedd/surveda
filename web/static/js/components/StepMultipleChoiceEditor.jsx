import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'
import Card from './Card'

class StepMultipleChoiceEditor extends Component {
  addChoice(e) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.addChoice())
  }

  deleteChoice(e, index) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.deleteChoice(index))
  }

  render() {
    const { step } = this.props
    const { choices } = step
    return (
      <div>
        <h5>Responses</h5>
        <p>List the strings you want to store for each possible choice and define valid values by commas.</p>
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
              <tr>
                <td colSpan='3'>
                  <a href='#!' onClick={(e) => this.addChoice(e)}>ADD</a>
                </td>
              </tr>
            </tbody>
          </table>
        </Card>
      </div>
    )
  }
}

StepMultipleChoiceEditor.propTypes = {
  dispatch: PropTypes.func,
  step: PropTypes.object.isRequired
}

export default connect()(StepMultipleChoiceEditor)
