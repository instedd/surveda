import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '.'
import * as routes from '../routes'

class SurveyTabs extends Component {
  render() {
    const { projectId, surveyId } = this.props

    return (
      <Tabs>
        <TabLink to={routes.survey(projectId, surveyId)}>Overview</TabLink>
        <TabLink to={routes.surveyRespondents(projectId, surveyId)}>Respondents</TabLink>
      </Tabs>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId
})

export default connect(mapStateToProps)(SurveyTabs)
