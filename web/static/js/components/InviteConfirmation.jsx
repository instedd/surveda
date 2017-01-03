import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../actions/invites'

class InviteConfirmation extends Component {
  confirmInvitation() {
    const code = this.props.location.query.code
    this.props.actions.confirm(code)
  }

  render() {
    // const projectId = this.props.location.query.projectId
    return (
      <div>
        <div> InviteShow </div>
        <a onClick={() => this.confirmInvitation()}> ACCEPT INVITATION </a>
      </div>
    )
  }
}

InviteConfirmation.propTypes = {
  location: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(InviteConfirmation)
