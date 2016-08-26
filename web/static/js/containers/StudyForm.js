import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/studies'
import { fetchStudies, fetchStudy, createStudy } from '../api'
import Study from './Study'

class StudyForm extends Component {
  componentDidMount() {
    const { dispatch, study_id } = this.props
    if(study_id) {
      fetchStudy(study_id).then(study => dispatch(actions.fetchStudiesSuccess(study)))
    }
  }

  componentDidUpdate() {
  }

  render(params) {
    let input
    const { study } = this.props
    return (<form onSubmit={ e => {
        e.preventDefault()

        const { dispatch, study } = this.props
        createStudy({name: input.value}).then(study => dispatch(actions.createStudy(study))).then(() => browserHistory.push('/studies')).catch((e) => dispatch(actions.fetchStudiesError(e)))
      }}>
        <div>
          <label>Study Name</label>
          <div>
            <input type="text" placeholder="Study name" value={study.name} ref={ node => { input = node }
            }/>
          </div>
        </div>
        <div>
          <button type="submit">
            Submit
          </button>
        </div>
      </form>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    study: state.studies.studies[ownProps.params.id] || {}
  }
}

export default withRouter(connect(mapStateToProps)(StudyForm))
