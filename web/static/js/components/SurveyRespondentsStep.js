import React, { PropTypes, Component } from 'react'
import { browserHistory } from 'react-router'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { uploadRespondents, fetchQuestionnaires } from '../api'
import * as actions from '../actions/surveys'
import * as respondentsActions from '../actions/respondents'

class SurveyQuestionnaireStep extends Component {

  componentDidMount() {
    const { dispatch, projectId, questionnaires, surveyId } = this.props
    if(projectId && surveyId) {
      dispatch(respondentsActions.fetchRespondents(projectId, surveyId))
    }
  }

  handleSubmit(survey, files) {
    const { dispatch, projectId } = this.props
    uploadRespondents(survey, files)
      .then(respondents => {dispatch(respondentsActions.receiveRespondents(respondents))})
      .catch((e) => dispatch(respondentsActions.receiveRespondentsError(e)))
  }

  render() {
    let files
    const { survey, questionnaires, respondentsCount, respondents } = this.props

    if (!survey) {
      return <div>Loading...</div>
    }
    if (respondentsCount != 0) {
      let count = 0
      let rows = []

      for(const respondentId of Object.keys(respondents)) {
        rows.push(<PhoneNumberRow id={respondentId} phoneNumber={respondents[respondentId].phoneNumber} key={respondentId}/>)
        count++
        if (count == 5) break
      }

      return (
        <div className="col s12 m7 offset-m1">
          <div className="row">
            <div className="col s12">
              <h4>Upload your respondents list</h4>
              <p className="flow-text">
                Upload a CSV file like this one with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.
              </p>
            </div>
          </div>

          <div className="row">
            <div className="col s12">
              <table className="ncdtable">
                <thead>
                  <tr>
                    <th>{`${respondentsCount} contacts imported`}</th>
                  </tr>
                </thead>
                <tbody>
                  {rows}
                </tbody>
              </table>
            </div>
          </div>

        </div>
      )
    }

    return (
      <div className="col s12 m7 offset-m1">
        <div className="row">
          <div className="col s12">
            <h4>Upload your respondents list</h4>
            <p className="flow-text">
              Upload a CSV file like this one with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.
            </p>
          </div>
        </div>
        <div className="row">
          <div className="col s12">
            <Dropzone className="dropfile" activeClassName="active" rejectClassName="rejectedfile" multiple={false} onDrop={file => {this.handleSubmit(survey, file)}}  accept="text/csv">
              <div className="drophere">
                <i className="material-icons">insert_drive_file</i>
                <div>Drop your CSV file here, or <a href='#!'>browse</a></div>
              </div>
              <div className="onlycsv">
                <i className="material-icons">block</i>
                <div>You can only drop CSV's files here</div>
              </div>
            </Dropzone>
          </div>
        </div>
      </div>
    )
  }

}

const PhoneNumberRow = ({id, phoneNumber}) => {
  return(
    <tr key={id}>
      <td>
        {phoneNumber}
      </td>
    </tr>
  )
}


const mapStateToProps = (state, ownProps) => {
  return{
    respondents: state.respondents,
    respondentsCount: Object.keys(state.respondents).length,
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.id,
    survey: state.surveys[ownProps.params.id]
  }
}

export default connect(mapStateToProps)(SurveyQuestionnaireStep);