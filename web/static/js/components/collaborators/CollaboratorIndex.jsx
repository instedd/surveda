import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { CardTable } from '../ui'
import * as actions from '../../actions/collaborators'

class CollaboratorIndex extends Component {
  componentDidMount() {
    const { projectId } = this.props
    if (projectId) {
      this.props.actions.fetchCollaborators(projectId)
    }
  }

  render() {
    const { project, collaborators } = this.props
    if (!collaborators) {
      return <div>Loading...</div>
    }
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
            { collaborators.map(c => {
              return (
                <tr key={c.email}>
                  <td> {c.email} </td>
                  <td> {c.role} </td>
                </tr>
              )
            })}
          </tbody>
        </CardTable>
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  collaborators: state.collaborators.items
})

export default connect(mapStateToProps, mapDispatchToProps)(CollaboratorIndex)
