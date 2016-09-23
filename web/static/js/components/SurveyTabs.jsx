import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '.'

class SurveyTabs extends Component {
  render() {
    const { projectId, surveyId } = this.props

    return (
      <Tabs>
        <TabLink to={`/projects/${projectId}/surveys/${surveyId}`}>Overview</TabLink>
        <TabLink to={`/projects/${projectId}/surveys/${surveyId}/respondents`}>Respondents</TabLink>
      </Tabs>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId,
})

export default connect(mapStateToProps)(SurveyTabs);
