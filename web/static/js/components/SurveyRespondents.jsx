import React, { Component } from 'react'
import { connect } from 'react-redux'
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
    const respondents = generateResponsesDictionaryFor(jQuery.extend(true, {}, this.props.respondents))
    const title = parseInt(Object.keys(respondents).length, 10) + " Respondents"

    if (Object.keys(respondents).length === 0) {
      return <div>Loading...</div>
    }

    function generateResponsesDictionaryFor(rs){
      Object.keys(rs).forEach((respondent_id, _) =>
        rs[respondent_id].responses = responsesDictionaryFrom(rs[respondent_id].responses)
      )
      return rs
    }

    function responsesDictionaryFrom(responseArray){
      const res = {}
      for (const key in responseArray){
        res[responseArray[key].name] = responseArray[key].value
      }
      return res
    }

    function allFieldNames(rs) {
      let fieldNames = Object.keys(rs).map((key) => (rs[key].responses))
      fieldNames = fieldNames.map((response) => Object.keys(response))
      return [].concat.apply([], fieldNames)
    }

    function respondentKeys(rs) {
      return Object.keys(rs)
    }

    function hasResponded(rs, respondent_id, fieldName){
      return Object.keys(rs[respondent_id].responses).includes(fieldName)
    }

    function responseOf(rs, respondent_id, fieldName){
      return hasResponded(rs, respondent_id, fieldName) ? rs[respondent_id].responses[fieldName] : "-"
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
                return <td key={parseInt(respondent_id, 10)+field}>{responseOf(respondents, respondent_id, field)}</td>
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
