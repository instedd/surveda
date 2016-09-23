import React, { PropTypes, Component } from 'react'
import { browserHistory } from 'react-router'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import * as respondentsActions from '../actions/respondents'
import CardTable from '../components/CardTable'

class SurveyRespondents extends Component {
  componentDidMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      dispatch(respondentsActions.fetchRespondents(projectId, surveyId))
    }
  }

  render() {
    /* jQuery extend clones respondents object, in order to build an easy to manage structure without
    modify state */
    let respondents = generateResponsesDictionaryFor(jQuery.extend(true, {}, this.props.respondents))
    const title = parseInt(Object.keys(respondents).length) + " Respondents"

    if (Object.keys(respondents).length === 0) {
      return <div>Loading...</div>
    }

    function generateResponsesDictionaryFor(respondents){
      Object.keys(respondents).forEach((respondent_id, _) =>
        respondents[respondent_id].responses = responsesDictionaryFrom(respondents[respondent_id].responses)
      )
      return respondents
    }

    function responsesDictionaryFrom(responseArray){
      let res = {}
      for (var key in responseArray){
        res[responseArray[key].name] = responseArray[key].value
      }
      return res
    }

    function allFieldNames(respondents) {
      let fieldNames = Object.keys(respondents).map((key) => (respondents[key].responses))
      fieldNames = fieldNames.map((response) => Object.keys(response))
      return [].concat.apply([], fieldNames)
    }

    function respondentKeys(respondents) {
      return Object.keys(respondents)
    }

    function hasResponded(respondents, respondent_id, fieldName){
      return Object.keys(respondents[respondent_id].responses).includes(fieldName)
    }

    function responseOf(respondents, respondent_id, fieldName){
      return hasResponded(respondents, respondent_id, fieldName) ? respondents[respondent_id].responses[fieldName] : "-"
    }

    return (
      <CardTable title={ title }>
        <thead>
          <tr>
            <th>Phone number</th>
            {allFieldNames(respondents).map(field =>
              <th key={field}>{field}</th>
            )}
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {respondentKeys(respondents).map(respondent_id =>
            <tr key={respondent_id}>
              <td> {respondents[respondent_id].phoneNumber}</td>
              {allFieldNames(respondents).map(function(field){
                return <td key={parseInt(respondent_id)+field}>{responseOf(respondents, respondent_id, field)}</td>
              })}
              <td>
                {respondents[respondent_id].date ? new Date(respondents[respondent_id].date).toUTCString() : "-"}
              </td>
            </tr>
          )}
        </tbody>
      </CardTable>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    respondents: state.respondents
  }
}

export default connect(mapStateToProps)(SurveyRespondents);
