import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
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
        <p><a onClick={this.addStudy}>Add!</a></p>
        Studies array!
        <table>
          <thead>
            <tr>
              <th>Name</th>
            </tr>
          </thead>
          <tbody>
            { this.props.studies.map((study) =>
              <tr key={study.id}>
                <td>
                  <Link to={'/studies/' + study.id}>{ study.name }</Link>
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
