import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/studies'
import { fetchStudies, createStudy } from '../api'

class Studies extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    fetchStudies().then(studies => dispatch(actions.fetchStudiesSuccess(studies)))
  }

  componentDidUpdate() {
  }

  render() {
    const { studies, ids } = this.props.studies
    return (
      <div>
        <p>
          <Link to='/studies/new'>Add study</Link>
        </p>
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
