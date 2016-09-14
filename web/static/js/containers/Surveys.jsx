import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import { ProjectTabs } from '../components'
import { Tooltip } from '../components/Tooltip'

class Surveys extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchSurveys(projectId))
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    createSurvey(projectId).then(response => {
      dispatch(actions.createSurvey(response))
      router.push(`/projects/${projectId}/surveys/${response.result}/edit`)
    })
  }

  render() {
    const { surveys, projectId } = this.props
    return (
      <div>
        <Tooltip text="Add survey">
          <a className="btn-floating btn-large waves-effect waves-light green right mtop" href="#" onClick={() => this.newSurvey() }>
            <i className="material-icons">add</i>
          </a>
        </Tooltip>
        { (Object.keys(surveys).length == 0) ?
          <div className="empty_page">
            <i className="material-icons">assignment_turned_in</i>
            <h5>You have no surveys on this project</h5>
          </div>
        :
          <div className="row">
            { Object.keys(surveys).map((surveyId) =>
              <div className="col s12 m6 l4" key={surveyId}>
                <div className="card white">
                  <div className="card-content">
                    <span className="card-title">
                      <Link className="black-text" to={`/projects/${projectId}/surveys/${surveyId}`}>{ surveys[surveyId].name }</Link>
                    </span>
                  </div>
                  <div className="card-action">
                    <Link className="grey-text text-lighten-1" to={`/projects/${projectId}/surveys/${surveyId}/edit`}><i className="material-icons">mode_edit</i></Link>
                  </div>
                </div>
              </div>
            )}
          </div>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveys: state.surveys
})

export default withRouter(connect(mapStateToProps)(Surveys))
