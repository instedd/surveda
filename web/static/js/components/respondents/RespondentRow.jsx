// @flow
import React, { Component } from 'react'
import dateformat from 'dateformat'
import { show } from '../../disposition'

type Props = {
  respondent: Respondent,
  responses: Response[],
  variantColumn: ?React$Element<*>
}

class RespondentRow extends Component {
  props: Props
  render() {
    const { respondent, responses, variantColumn } = this.props

    return (
      <tr key={respondent.id}>
        <td> {respondent.phoneNumber}</td>
        {responses.map((response) => {
          return <td key={parseInt(respondent.id) + response.name}>{response.value}</td>
        })}
        {variantColumn}
        <td>
          {show(respondent.disposition)}
        </td>
        <td>
          {respondent.date ? dateformat(new Date(respondent.date), 'mmm d, yyyy HH:MM') : '-'}
        </td>
      </tr>
    )
  }
}

export default RespondentRow
