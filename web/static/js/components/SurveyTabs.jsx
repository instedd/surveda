import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Tabs from './Tabs'
import TabLink from './TabLink'
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

SurveyTabs.propTypes = {
  projectId: PropTypes.number,
  surveyId: PropTypes.number
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  surveyId: parseInt(ownProps.params.surveyId)
})

export default connect(mapStateToProps)(SurveyTabs)
