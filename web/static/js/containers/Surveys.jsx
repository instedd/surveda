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
  let icon = 'not_interested'
  let color = "black-text"
  switch (survey.state) {
    case 'running':
      icon = 'play_arrow'
      color = 'green-text'
      break;
    case 'ready':
      icon = 'done'
      color = "black-text"
      break;
    case 'completed':
      icon = 'done_all'
      color = "black-text"
      break;
  }

  return(
    <Card
      title={
        <SurveyLink className="black-text" survey={ survey }>{ survey.name }</SurveyLink>
      }
    >
      <SurveyLink className={ color } survey={survey}>
        <i className="material-icons">{icon}</i>
        {survey.state}
      </SurveyLink>
    </Card>
  )
}
