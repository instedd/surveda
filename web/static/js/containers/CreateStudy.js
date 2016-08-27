import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/studies'
import { fetchStudies, fetchStudy, createStudy } from '../api'
import Study from './Study'
import StudyForm from '../components/StudyForm'

class CreateStudy extends Component {
  componentDidUpdate() {
  }

  handleSubmit(dispatch) {
    return (study) => {
      createStudy(study)
        .then(study => dispatch(actions.createStudy(study)))
        .then(() => browserHistory.push('/studies'))
        .catch((e) => dispatch(actions.fetchStudiesError(e)))
    }
  }

  render(params) {
    let input
    const { study } = this.props
    return (
      <StudyForm onSubmit={this.handleSubmit(this.props.dispatch)} study={study} />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    study: state.studies.studies[ownProps.params.id] || {}
  }
}

export default withRouter(connect(mapStateToProps)(CreateStudy))
