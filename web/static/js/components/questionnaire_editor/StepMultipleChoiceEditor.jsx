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

  changeChoice(index) {
    const { dispatch } = this.props
    return (value, responses) => {
      dispatch(actions.changeChoice(index, value, responses))
    }
  }

  render() {
    const { step } = this.props
    const { choices } = step
    return (
      <div>
        <h5>Responses</h5>
        <p><b>List the texts you want to store for each possible choice and define valid values by commas.</b></p>
        <Card>
          <div className='card-table'>
              <table>
                <thead>
                  <tr>
                    <th>Response</th>
                    <th>SMS</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  { choices.map((choice, index) =>
                    <ChoiceEditor
                      key={index}
                      choice={choice}
                      onDelete={(e) => this.deleteChoice(e, index)}
                      onChoiceChange={this.changeChoice(index)}
                      />
                  )}
                </tbody>
              </table>
          </div>
          <div className='card-action'>
            <a className="blue-text" href='#!' onClick={(e) => this.addChoice(e)}><b>ADD</b></a>
          </div>
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
