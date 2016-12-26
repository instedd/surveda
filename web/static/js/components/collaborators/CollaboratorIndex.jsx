import React, { Component } from 'react'
import { CardTable } from '../ui'

class CollaboratorIndex extends Component {
  render() {
    return (
      <div>
        <CardTable title='Collaborators'>
          <thead>
            <tr>
              <th>Email</th>
              <th>Role</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>dummy-mail@manas.com.ar</td>
              <td>no-role</td>
            </tr>
          </tbody>
        </CardTable>
      </div>
    )
  }
}

export default CollaboratorIndex
