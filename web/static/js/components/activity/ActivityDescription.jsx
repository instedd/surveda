import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'

class ActivityDescription extends Component {
  text(activity) {
    const { t } = this.props
    const metadata = activity.metadata || {}
    let reportType
    switch (activity.entityType) {
      case 'survey':
        const surveyName = metadata['surveyName'] || 'Untitled'
        switch (activity.action) {
          case 'create':
            return t('Created survey')
          case 'rename':
            const {oldSurveyName, newSurveyName} = metadata
            if (oldSurveyName) {
              return t('Renamed <i>{{oldSurveyName}}</i> survey to <i>{{newSurveyName}}</i>', {oldSurveyName: oldSurveyName, newSurveyName: newSurveyName})
            } else {
              return t('Named survey as <i>{{newSurveyName}}</i>', {newSurveyName: newSurveyName})
            }
          case 'edit':
            return t('Edited <i>{{surveyName}}</i> survey', {surveyName: surveyName})
          case 'delete':
            return t('Deleted <i>{{surveyName}}</i> survey', {surveyName: surveyName})
          case 'start':
            return t('Started <i>{{surveyName}}</i> survey', {surveyName: surveyName})
          case 'stop':
            return t('Paused <i>{{surveyName}}</i> survey', {surveyName: surveyName})
          case 'download':
            reportType = metadata['reportType'].split('_').join(' ')
            return t('Downloaded <i>{{surveyName}}</i> {{reportType}}', {surveyName: surveyName, reportType: reportType})
          case 'enable_public_link':
            reportType = metadata['reportType'].split('_').join(' ')
            return t('Enabled <i>{{surveyName}}</i> {{reportType}} link', {surveyName: surveyName, reportType: reportType})
          case 'disable_public_link':
            reportType = metadata['reportType'].split('_').join(' ')
            return t('Disabled <i>{{surveyName}}</i> {{reportType}} link', {surveyName: surveyName, reportType: reportType})
          case 'regenerate_public_link':
            reportType = metadata['reportType'].split('_').join(' ')
            return t('Reset <i>{{surveyName}}</i> {{reportType}} link', {surveyName: surveyName, reportType: reportType})
          default:
            return ''
        }
      case 'project':
        switch (activity.action) {
          case 'create_invite':
            return t('Invited {{collaboratorEmail}} as {{role}}', {collaboratorEmail: metadata['collaboratorEmail'], role: metadata['role']})
          case 'edit_invite':
            return t('Updated invitation for {{collaboratorEmail}} from {{oldRole}} to {{newRole}}', {collaboratorEmail: metadata['collaboratorEmail'], oldRole: metadata['oldRole'], newRole: metadata['newRole']})
          case 'delete_invite':
            return t('Deleted invitation for {{collaboratorEmail}} as {{role}}', {collaboratorEmail: metadata['collaboratorEmail'], role: metadata['role']})
          case 'edit_collaborator':
            return t('Updated membership for {{collaboratorName}} from {{oldRole}} to {{newRole}}', {collaboratorName: metadata['collaboratorName'], oldRole: metadata['oldRole'], newRole: metadata['newRole']})
          case 'remove_collaborator':
            return t('Deleted {{role}} membership for {{collaboratorName}}', {collaboratorName: metadata['collaboratorName'], role: metadata['role']})
          default:
            return ''
        }
      default:
        return ''
    }
  }

  render() {
    const { activity } = this.props
    return (
      <span dangerouslySetInnerHTML={{__html: this.text(activity)}} />
    )
  }
}

ActivityDescription.propTypes = {
  t: PropTypes.func,
  activity: PropTypes.object
}

export default translate()(ActivityDescription)
