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
    return (response, smsValues, ivrValues, skipLogic, autoComplete = false) => {
      actions.changeChoice(step.id, index, response, smsValues, ivrValues, skipLogic, autoComplete)
    }
  }

  render() {
    const { questionnaire, step, stepsBefore, stepsAfter, errors, errorPath } = this.props
    const { choices } = step

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let myErrors = errors[`${errorPath}.choices`]
    if (myErrors) {
      myErrors.join(', ')
    }

    return (
      <div>
        <h5>Responses</h5>
        <p><b>List the texts you want to store for each possible choice and define valid values by commas.</b></p>
        <Card>
          <div className='card-table'>
            <table className='responses-table'>
              <thead>
                <tr>
                  <th style={{width: '25%'}}>Response</th>
                  { sms
                  ? <th style={{width: '20%'}}>SMS</th>
                  : null
                  }
                  { ivr
                  ? <th style={{width: '20%'}}>Phone call</th>
                  : null
                  }
                  <th style={{width: '30%'}}>Skip logic</th>
                  <th style={{width: '5%'}} />
                </tr>
              </thead>
              <tbody>
                { choices.map((choice, index) =>
                  <ChoiceEditor
                    key={index}
                    questionnaire={questionnaire}
                    choice={choice}
                    onDelete={(e) => this.deleteChoice(e, index)}
                    onChoiceChange={this.changeChoice(index)}
                    stepsAfter={stepsAfter}
                    stepsBefore={stepsBefore}
                    sms={sms}
                    ivr={ivr}
                    errors={errors}
                    errorPath={`${errorPath}.choices[${index}]`}
                      />
                  )}
              </tbody>
            </table>
          </div>
          <div className='row'>
            <div className='col s2 card-action'>
              <a className='blue-text' href='#!' onClick={(e) => this.addChoice(e)}><b>ADD</b></a>
            </div>
            { myErrors
            ? <div className='col s10 card-action-error'>
              {myErrors}
            </div>
            : null
            }
          </div>
        </Card>
      </div>
    )
  }
}

StepMultipleChoiceEditor.propTypes = {
  actions: PropTypes.object.isRequired,
  questionnaire: PropTypes.object.isRequired,
  step: PropTypes.object.isRequired,
  stepsBefore: PropTypes.array,
  stepsAfter: PropTypes.array,
  errors: PropTypes.object.isRequired,
  errorPath: PropTypes.string.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepMultipleChoiceEditor)
