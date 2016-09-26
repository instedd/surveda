import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'
import surveyRoute from '../components/SurveyRoute'
import * as channelsActions from '../actions/channels'

class SurveyIndex extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchSurveys(projectId))
    dispatch(channelsActions.fetchChannels());
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    createSurvey(projectId).then(response => {
      dispatch(actions.createSurvey(response))
      router.push(`/projects/${projectId}/surveys/${response.result}/edit`)
    })
  }

  render() {
    const { surveys, router, channels } = this.props

    if ( channels == null || surveys == null) {
      return(<div>Loading...</div>)
    }

    const title = parseInt(Object.keys(surveys).length, 10) + " Surveys"

    return (
      <div>
        <AddButton text="Add survey" onClick={ () => this.newSurvey() } />
        { (Object.keys(surveys).length == 0) ?
          <EmptyPage icon='assignment_turned_in' title='You have no surveys on this project' onClick={(e) => this.newSurvey(e)} />
        :
          <CardTable highlight={true} title={ title }>
            <thead>
              <tr>
                <th>Name</th>
                <th>Mode</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              { (Object.keys(surveys).map( function (surveyId){
                const survey = surveys[surveyId]
                const channelMode = survey.channels.length > 0 ? channels[survey.channels[0]].type : "-"
                return(
                  <SurveyRow survey={survey} mode={channelMode} router={router} key={surveyId}/>
                )}
              ))}
            </tbody>
          </CardTable>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveys: state.surveys,
  channels: state.channels
})

export default withRouter(connect(mapStateToProps)(SurveyIndex))

const SurveyRow = ({ survey, mode, router }) => {
  let color = "black-text"
  let text = 'Editing'
  switch (survey.state) {
    case 'running'  :
      color = 'green-text'
      text = 'Running'
      break;
    case 'ready':
      color = "black-text"
      text = 'Ready to launch'
      break;
    case 'completed':
      color = "black-text"
      text = 'Completed'
      break;
  }

  return(
    <tr onClick={() => router.push(surveyRoute(survey))}>
      <td>{survey.name}</td>
      <td>{mode}</td>
      <td>
        <span className={ color }>
          { text }
        </span>
      </td>
    </tr>
  )
}

{/*
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
      <div className="col s12 m6 l4">
        <Card>
          <div className="card-content">
            <span className="card-title">
              { survey.name }
            </span>
            <p className={ color }>
              <i className="material-icons">{icon}</i>
              { text }
            </p>
          </div>
        </Card>
      </div>
    </SurveyLink>
  )
}
*/}
