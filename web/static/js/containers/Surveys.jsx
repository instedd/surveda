import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import { Tooltip } from '../components/Tooltip'
import SurveyLink from '../components/SurveyLink'
import Card from '../components/Card'

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
    const { surveys } = this.props
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
              <SurveyCard survey={surveys[surveyId]} key={surveyId}/>
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

const SurveyCard = ({ survey }) => (
  <Card
    title={
      <SurveyLink className="black-text" survey={ survey }>{ survey.name }</SurveyLink>
    }
  >
    <SurveyLink className="grey-text text-lighten-1" survey={survey}>
      <i className="material-icons">mode_edit</i>
    </SurveyLink>
  </Card>
)
