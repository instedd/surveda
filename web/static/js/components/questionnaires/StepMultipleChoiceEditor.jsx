import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaire'
import ChoiceEditor from './ChoiceEditor'
import { Card } from '../ui'
import { getChoiceResponseSmsJoined } from '../../step'
import * as api from '../../api'

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

  smsAutocompleteGetData(value, callback, choice, index) {
    const { questionnaire } = this.props

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, 'sms', defaultLanguage, value)
      .then(response => {
        const items = response.map(r => ({id: r.text, text: r.text, translations: r.translations}))
        this.smsAutocompleteItems = items
        callback(value, items)
      })
    } else {
      let sms = getChoiceResponseSmsJoined(choice, defaultLanguage)
      if (sms.length == 0) return

      api.autocompleteOtherLanguage(questionnaire.projectId, 'sms', defaultLanguage, activeLanguage, sms, value)
      .then(response => {
        const items = response.map(r => ({id: r, text: r}))
        this.smsAutocompleteItems = items
        callback(value, items)
      })
    }
  }

  smsAutocompleteOnSelect(item, choice, index) {
    const { questionnaire, step, actions } = this.props

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage
    const editor = this.refs[`choiceEditor${index}`]

    if (activeLanguage == defaultLanguage) {
      let value = this.smsAutocompleteItems.find(i => i.id == item.id)
      actions.autocompleteChoiceSmsValues(step.id, index, value)
      editor.smsChange(null, value.text)
    } else {
      editor.smsChange(null, item.text)
    }

    editor.exitEditMode()
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
                    ref={`choiceEditor${index}`}
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
                    smsAutocompleteGetData={(value, callback) => this.smsAutocompleteGetData(value, callback, choice, index)}
                    smsAutocompleteOnSelect={item => this.smsAutocompleteOnSelect(item, choice, index)}
                    />
                  )}
              </tbody>
            </table>
          </div>
          <div className='card-action'>
            <a className='blue-text' href='#!' onClick={(e) => this.addChoice(e)}><b>ADD</b></a>
            { myErrors
            ? <span className='card-error'>{myErrors}</span>
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
