import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/studies'
import { fetchStudies, createStudy } from '../api'

class Studies extends Component {
  constructor(props) {
    super(props)
    this.createStudy = this.createStudy.bind(this)
  }

  componentDidMount() {
    const { dispatch } = this.props
    fetchStudies().then(studies => dispatch(actions.fetchStudiesSuccess(studies)))
  }

  componentDidUpdate() {
  }

  createStudy(e) {
    e.preventDefault()

    const { dispatch } = this.props
    createStudy().then(study => dispatch(actions.createStudy(study))).catch((e) => dispatch(actions.fetchStudiesError(e)))
  }

  render() {
    const { studies, ids } = this.props.studies
    return (
      <div>
        <p><a onClick={this.createStudy}>Add!</a></p>
        Studies array!
        <table>
          <thead>
            <tr>
              <th>Name</th>
            </tr>
          </thead>
          <tbody>
            { ids.map((study_id) =>
              <tr key={study_id}>
                <td>
                  <Link to={'/studies/' + study_id}>{ studies[study_id].name }</Link>
                </td>
              </tr>
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

export default connect(mapStateToProps)(Studies)
