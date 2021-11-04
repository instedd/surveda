// @flow
import React, {Component} from 'react'
import dateformat from 'dateformat'
import languageNames from 'language-names'
import capitalize from 'lodash/capitalize'
import { fieldUniqueKey, isFieldSelected } from '../../reducers/respondents'

type Props = {
  respondent: Respondent,
  responses: Array<Response>,
  variantColumn: ?React$Element<*>,
  surveyModes: Array<string>,
  cellClassNames: Function,
  selectedFields: Array<string>
}

class RespondentRow extends Component<Props> {
  isFieldSelected(fieldType: string, fieldKey: string) {
    const { selectedFields } = this.props
    return isFieldSelected(selectedFields, fieldUniqueKey(fieldType, fieldKey))
  }

  getModeAttemptsValues() {
    const {respondent, surveyModes} = this.props
    let modeValueRow = surveyModes
      .filter(mode => this.isFieldSelected('mode', mode))
      .map(function(element, index) {
        let modeValue = 0
        if (respondent.stats.attempts) {
          modeValue = respondent.stats.attempts[element] ? respondent.stats.attempts[element] : 0
        }
        return <td className='tdNumber' key={index}>{modeValue}</td>
      })
    return modeValueRow
  }

  render() {
    const {respondent, responses, variantColumn, cellClassNames, selectedFields} = this.props
    return (
      <tr key={respondent.id}>
        {/* If no field is selected, render an empty row */}
        {selectedFields.length ? null : <td className='center'>-</td>}
        {this.isFieldSelected('fixed', 'phone_number') ? <td>{respondent.phoneNumber}</td> : null}
        {this.isFieldSelected('fixed', 'disposition') ? <td>{capitalize(respondent.disposition)}</td> : null}
        {
          this.isFieldSelected('fixed', 'date')
          ? <td className='tdDate'>
            {respondent.date ? dateformat(new Date(respondent.date), 'mmm d, yyyy HH:MM') : '-'}
          </td>
          : null
        }
        {this.getModeAttemptsValues()}
        {this.isFieldSelected('variant', 'variant') ? variantColumn : null}
        {
          respondent.partialRelevant &&
            this.isFieldSelected('partial_relevant', 'answered_questions')
            ? <td className='tdNumber'>
              {respondent.partialRelevant.answeredCount}
            </td>
            : null
        }
        {
          responses
            .filter(response => this.isFieldSelected('response', response.name))
            .map((response) => {
            // For the 'language' variable we convert the code to the native name
              let value = response.value
              if (response.name == 'language') {
                value = languageNames[value] || value
              }

              return <td
                className={cellClassNames(response.name)}
                key={parseInt(respondent.id) + response.name}>
                {value}
              </td>
            })
        }
      </tr>
    )
  }
}

export default RespondentRow
