import React, { Component, PropTypes } from 'react'

class InviteShow extends Component {
  render() {
    const code = this.props.location.query.code
    return (
      <div>
        <div> InviteShow </div>
        <div> {code} </div>
      </div>
    )
  }
}

InviteShow.propTypes = {
  location: PropTypes.object.isRequired
}

export default InviteShow
