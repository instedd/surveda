import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { fetchSurvey } from '../api'

class Survey extends Component {
  componentDidMount() {
    const { dispatch, survey_id } = this.props
    // if (survey_id) {
    //   fetchSurvey(survey_id).then(survey => dispatch(actions.fetchSurveysSuccess(survey)))
    // } else {
    //   dispatch(actions.fetchSurveysError(`Id is not defined`))
    // }
  }

  componentDidUpdate() {
  }

  render(params) {
    const { survey } = this.props
    if(survey) {
      return (
        <div>
          <h3>Survey view</h3>
          <h4>Name: { survey.name }</h4>
          <br/>
          <br/>
          <Link to={`/surveys/${survey.id}/edit`}>Edit</Link>
          {' '}
          <Link to='/surveys'>Back</Link>
          {' '}
          <Link to={`/surveys/${survey.id}/surveys`}>Surveys</Link>
        </div>
      )
    } else {
      return <p>Loading...</p>
    }
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    survey_id: ownProps.params.surveyId,
    survey: state.surveys[ownProps.params.surveyId]
  }
}

export default withRouter(connect(mapStateToProps)(Survey))
