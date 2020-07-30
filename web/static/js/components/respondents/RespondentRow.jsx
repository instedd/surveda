// @flow
import React, {Component} from 'react'
import dateformat from 'dateformat'
import languageNames from 'language-names'
import capitalize from 'lodash/capitalize'
import { fieldUniqueKey } from '../../reducers/respondents'

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
    return selectedFields.some(key => key == fieldUniqueKey(fieldType, fieldKey))
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
    const {respondent, responses, variantColumn, cellClassNames} = this.props
    return (
      <tr key={respondent.id}>
        {this.isFieldSelected('fixed', 'phoneNumber') ? <td>{respondent.phoneNumber}</td> : null}
        {this.isFieldSelected('fixed', 'disposition') ? <td>{capitalize(respondent.disposition)}</td> : null}
        {
          this.isFieldSelected('fixed', 'updated_at')
          ? <td className='tdDate'>
            {respondent.date ? dateformat(new Date(respondent.date), 'mmm d, yyyy HH:MM') : '-'}
          </td>
          : null
        }
        {this.getModeAttemptsValues()}
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
        {this.isFieldSelected('variant', 'variant') ? variantColumn : null}
      </tr>
    )
  }
}

export default RespondentRow
