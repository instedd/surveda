import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import SurveyLink from '../components/SurveyLink'
import Card from '../components/Card'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'

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
        <AddButton text="Add survey" onClick={ () => this.newSurvey() } />
        { (Object.keys(surveys).length == 0) ?
          <EmptyPage icon='assignment_turned_in' title='You have no surveys on this project' onClick={(e) => this.newSurvey(e)} />
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

const SurveyCard = ({ survey }) => {
  let icon = 'mode_edit'
  let color = "black-text"
  let text = 'Editing'
  switch (survey.state) {
    case 'running':
      icon = 'play_arrow'
      color = 'green-text'
      text = 'Running'
      break;
    case 'ready':
      icon = 'play_circle_outline'
      color = "black-text"
      text = 'Ready to launch'
      break;
    case 'completed':
      icon = 'done'
      color = "black-text"
      text = 'Completed'
      break;
  }

  return(
    <SurveyLink className="black-text" survey={ survey }>
      <Card>
        <div className="card-content">
          <span className="card-title">
            { survey.name }
          </span>
          <p className={ color }>
            <i className="material-icons" style={{ verticalAlign: 'middle' }}>{icon}</i>
            { text }
          </p>
        </div>
      </Card>
    </SurveyLink>
  )
}
