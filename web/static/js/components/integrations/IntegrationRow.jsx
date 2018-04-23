// @flow
import React, { Component } from 'react'

type Props = {
  integration: Integration
}

class IntegrationRow extends Component {
  props: Props
  render() {
    const { integration } = this.props

    return (
      <tr key={integration.id}>
        <td>{integration.name}</td>
        <td>{integration.uri}</td>
        <td>{integration.authToken}</td>
        <td>{integration.state}</td>
      </tr>
    )
  }
}

export default IntegrationRow
