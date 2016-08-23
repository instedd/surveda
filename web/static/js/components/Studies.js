import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Study from '../containers/Study'
import * as actions from '../actions'
import { fetchStudies, createStudy } from '../api'

class Studies extends Component {
  constructor(props) {
    super(props)
    this.addStudy = this.addStudy.bind(this)
  }

  componentDidMount() {
    const { dispatch } = this.props
    fetchStudies().then(studies => dispatch(actions.fetchStudiesSuccess(studies)))
  }

  componentDidUpdate() {
  }

  addStudy(e) {
    e.preventDefault()

    const { dispatch } = this.props
    createStudy().then(study => dispatch(actions.addStudy(study))).catch((e) => dispatch(actions.fetchStudiesError(e)))
  }

  render() {
    return (
      <div>
        <a onClick={this.addStudy}>Add!</a>
        Studies array!
        <table>
          <thead>
            <tr>
              <th>Name</th>
            </tr>
          </thead>
          <tbody>
            { this.props.studies.map((study) =>
              <Study study={study} key={study.id} />
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    studies: state.studies
  }
}

Studies = connect(mapStateToProps)(Studies);

export default Studies;
