import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/studies'
import { fetchStudy } from '../api'

class Study extends Component {
  componentDidMount() {
    const { dispatch, study_id } = this.props
    if(study_id){
      fetchStudy(study_id).then(study => dispatch(actions.fetchStudiesSuccess(study)))
    } else {
      dispatch(actions.fetchStudiesError(`Id is not defined`))
    }
  }

  componentDidUpdate() {
  }

  render(params) {
    const { study } = this.props
    if(study) {
      return (
        <div>
          <h3>Study view</h3>
          <h4>Name: { study.name }</h4> 
          <br/>
          <br/>
          <Link to={`/studies/${study.id}/edit`}>Edit </Link>
          <Link to='/studies'> Back</Link>
        </div>
      )
    } else {
      return <p>Loading...</p>
    }
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    study_id: ownProps.params.id,
    study: state.studies.studies[ownProps.params.id]
  }
}

export default withRouter(connect(mapStateToProps)(Study))
