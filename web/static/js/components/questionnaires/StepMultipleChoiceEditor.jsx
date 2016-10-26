import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaire'
import ChoiceEditor from './ChoiceEditor'
import { Card } from '../ui'

class StepMultipleChoiceEditor extends Component {
  addChoice(e) {
    e.preventDefault()
    this.props.actions.addChoice()
  }

  deleteChoice(e, index) {
    e.preventDefault()
    this.props.actions.deleteChoice(index)
  }

  changeChoice(index) {
    return (value, responses) => {
      this.props.actions.changeChoice(index, value, responses)
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
                  <th />
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
            <a className='blue-text' href='#!' onClick={(e) => this.addChoice(e)}><b>ADD</b></a>
          </div>
        </Card>
      </div>
    )
  }
}

StepMultipleChoiceEditor.propTypes = {
  actions: PropTypes.object.isRequired,
  step: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepMultipleChoiceEditor)
