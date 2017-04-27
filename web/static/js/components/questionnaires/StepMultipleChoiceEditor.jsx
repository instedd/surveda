// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaire'
import ChoiceEditor from './ChoiceEditor'
import { Card } from '../ui'
import { getChoiceResponseSmsJoined } from '../../step'
import * as api from '../../api'

type Props = {
  actions: any,
  questionnaire: Questionnaire,
  readOnly: boolean,
  step: MultipleChoiceStep,
  stepIndex: number,
  stepsBefore: Step[],
  stepsAfter: Step[],
  errorPath: string,
  errorsByPath: ErrorsByPath
};

class StepMultipleChoiceEditor extends Component {
  props: Props
  smsAutocompleteItems: AutocompleteItem[]

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
    return (response, smsValues, ivrValues, mobilewebValues, skipLogic, autoComplete = false) => {
      actions.changeChoice(step.id, index, response, smsValues, ivrValues, mobilewebValues, skipLogic, autoComplete)
    }
  }

  smsAutocompleteGetData(value, callback, choice, index) {
    const { questionnaire } = this.props

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, 'sms', 'response', defaultLanguage, value)
      .then(response => {
        const items = response.map(r => ({id: r.text, text: r.text, translations: r.translations}))
        this.smsAutocompleteItems = items
        callback(value, items)
      })
    } else {
      let sms = getChoiceResponseSmsJoined(choice, defaultLanguage)
      if (sms.length == 0) return

      api.autocompleteOtherLanguage(questionnaire.projectId, 'sms', 'response', defaultLanguage, activeLanguage, sms, value)
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
      editor.smsChange(null, (value || {}).text)
    } else {
      editor.smsChange(null, item.text)
    }

    editor.exitEditMode()
  }

  render() {
    const { questionnaire, readOnly, step, stepIndex, stepsBefore, stepsAfter, errorPath, errorsByPath } = this.props
    const { choices } = step

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1
    const mobileweb = questionnaire.modes.indexOf('mobileweb') != -1

    const choicesErrorPath = `${errorPath}.choices`

    let myErrors = errorsByPath[choicesErrorPath]
    if (myErrors) {
      myErrors.join(', ')
    }

    return (
      <div>
        <h5>Responses</h5>
        <p><b>List the texts you want to store for each possible choice and define valid values by commas.</b></p>
        <Card className='scrollX'>
          <div className='card-table'>
            <table className='responses-table'>
              <thead>
                <tr>
                  <th style={{width: '25%'}}>Response</th>
                  { sms
                  ? <th style={{width: '15%'}}>SMS</th>
                  : null
                  }
                  { ivr
                  ? <th style={{width: '15%'}}>Phone call</th>
                  : null
                  }
                  { mobileweb
                  ? <th style={{width: '15%'}}>Mobile web</th>
                  : null
                  }
                  <th style={{width: '25%'}}>Skip logic</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                { choices.map((choice, index) =>
                  <ChoiceEditor
                    ref={`choiceEditor${index}`}
                    key={index}
                    stepIndex={stepIndex}
                    choiceIndex={index}
                    lang={questionnaire.activeLanguage}
                    choice={choice}
                    readOnly={readOnly}
                    onDelete={(e) => this.deleteChoice(e, index)}
                    onChoiceChange={this.changeChoice(index)}
                    stepsAfter={stepsAfter}
                    stepsBefore={stepsBefore}
                    sms={sms}
                    ivr={ivr}
                    mobileweb={mobileweb}
                    errorPath={choicesErrorPath}
                    errorsByPath={errorsByPath}
                    smsAutocompleteGetData={(value, callback) => this.smsAutocompleteGetData(value, callback, choice, index)}
                    smsAutocompleteOnSelect={item => this.smsAutocompleteOnSelect(item, choice, index)}
                    />
                  )}
              </tbody>
            </table>
          </div>
          {readOnly ? null
            : <div className='card-action'>
              <a className='blue-text' href='#!' onClick={(e) => this.addChoice(e)}><b>ADD</b></a>
              { myErrors
            ? <span className='card-error'>{myErrors}</span>
            : null
            }
            </div>
          }
        </Card>
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepMultipleChoiceEditor)
