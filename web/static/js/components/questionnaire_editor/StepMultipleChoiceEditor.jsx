import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaireEditor'
import ChoiceEditor from './ChoiceEditor'
import Card from '../Card'

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

  editChoice(e, index) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.editChoice(index))
  }

  render() {
    const { step } = this.props
    const { choices } = step
    return (
      <div>
        <h5>Responses</h5>
        <p>List the strings you want to store for each possible choice and define valid values by commas.</p>
        <Card>
          <ul className='collection'>
            <li className='collection-item'>
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
                    <ChoiceEditor
                      key={index}
                      choice={choice}
                      onDelete={(e) => this.deleteChoice(e, index)}
                      onValueClick={(e) => this.editChoice(e, index)}
                      editing={false} />
                  )}
                </tbody>
              </table>
            </li>
            <li className='collection-item'>
              <a href='#!' onClick={(e) => this.addChoice(e)}>ADD</a>
            </li>
          </ul>
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
