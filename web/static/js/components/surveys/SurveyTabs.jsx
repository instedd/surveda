import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '../ui'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

class SurveyTabs extends Component {
  render() {
    const { projectId, surveyId, t } = this.props

    return (
      <Tabs id='survey_tabs'>
        <TabLink key='overview' tabId='survey_tabs' to={routes.survey(projectId, surveyId)}>{t('Overview')}</TabLink>
        <TabLink key='respondents' tabId='survey_tabs' to={routes.surveyRespondents(projectId, surveyId)}>{t('Respondents')}</TabLink>
        <TabLink key='settings' tabId='survey_tabs' to={routes.surveySettings(projectId, surveyId)}>{t('Settings')}</TabLink>
        <TabLink key='integrations' tabId='survey_tabs' to={routes.surveyIntegrations(projectId, surveyId)}>{t('Integrations')}</TabLink>
      </Tabs>
    )
  }
}

SurveyTabs.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any,
  surveyId: PropTypes.any
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId,
  survey: state.survey.data
})

export default translate()(connect(mapStateToProps)(SurveyTabs))
