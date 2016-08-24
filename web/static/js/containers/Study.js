import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'

class Study extends Component {
  render(params) {
    const { study } = this.props
    return (
      <div>
        <h1>{ study.name }</h1>
        <Link to='/studies'>Back</Link>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    study: state.studies[ownProps.params.id-1]
  }
}

export default withRouter(connect(mapStateToProps)(Study))
