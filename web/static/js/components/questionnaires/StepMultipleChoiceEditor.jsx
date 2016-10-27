import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaire'
import ChoiceEditor from './ChoiceEditor'
import { Card } from '../ui'

class StepMultipleChoiceEditor extends Component {
  addChoice(e) {
    const { step, actions } = this.props
    e.preventDefault()
    actions.addChoice(step.id)
  }

  deleteChoice(e, index) {
    const { step, actions } = this.props
    e.preventDefault()
    actions.deleteChoice(step.id, index)
  }

  changeChoice(index) {
    const { step, actions } = this.props
    return (value, responses) => {
      actions.changeChoice(step.id, index, value, responses)
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
            <table className='responses-table'>
              <thead>
                <tr>
                  <th style={{width: '45%'}}>Response</th>
                  <th style={{width: '45%'}}>SMS</th>
                  <th style={{width: '10%'}} />
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
