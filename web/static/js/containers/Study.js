import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions'
import { fetchStudies } from '../api'

class Study extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    fetchStudies().then(studies => dispatch(actions.fetchStudiesSuccess(studies)))
  }

  componentDidUpdate() {
  }

  render(params) {
    const { study } = this.props
    if(study) {
      return (
        <div>
          <h1>{ study.name }</h1>
          <Link to='/studies'>Back</Link>
        </div>
      )
    } else {
      return <p>Loading...</p>
    }
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    study: state.studies.studies[ownProps.params.id]
  }
}

export default withRouter(connect(mapStateToProps)(Study))
