// @flow
import React, {Component} from 'react'
import dateformat from 'dateformat'
import languageNames from 'language-names'
import capitalize from 'lodash/capitalize'

type Props = {
  respondent: Respondent,
  responses: Response[],
  variantColumn: ?React$Element<*>,
  surveyModes: string[]
};

class RespondentRow extends Component<Props> {

  getModeAttemptsValues() {
    const {respondent, surveyModes} = this.props
    let modeValueRow = surveyModes.map(function(element, index) {
      let modeValue = 0
      if (respondent.stats.attempts) {
        modeValue = respondent.stats.attempts[element] ? respondent.stats.attempts[element] : 0
      }
      return <td className="tdNumber" key={index}>{modeValue}</td>
    })
    return modeValueRow
  }

  render() {
    const {respondent, responses, variantColumn} = this.props
    return (
      <tr key={respondent.id}>
        <td> {respondent.phoneNumber}</td>
        {responses.map((response) => {
          // For the 'language' variable we convert the code to the native name
          let value = response.value
          if (response.name == 'language') {
            value = languageNames[value] || value
          }

          return <td className='tdNowrap' key={parseInt(respondent.id) + response.name}>{value}</td>
        })}
        {variantColumn}
        <td>
          {capitalize(respondent.disposition)}
        </td>
        <td className="tdDate">
          {respondent.date ? dateformat(new Date(respondent.date), 'mmm d, yyyy HH:MM') : '-'}
        </td>
        {this.getModeAttemptsValues()}
      </tr>
    )
  }
}

export default RespondentRow
