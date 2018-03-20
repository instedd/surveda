import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'

class ActivityDescription extends Component {
  text(activity) {
    const { t } = this.props
    const metadata = activity.metadata
    let text, reportType
    switch (activity.entityType) {
      case 'survey':
        switch (activity.action) {
          case 'download':
            reportType = activity.metadata['reportType'].split('_').join(' ')
            text = t('Downloaded <i>{{surveyName}}</i> {{reportType}}', {surveyName: metadata['surveyName'], reportType: reportType})
            break
          case 'enable_public_link':
            reportType = activity.metadata['reportType'].split('_').join(' ')
            text = t('Enabled <i>{{surveyName}}</i> {{reportType}} link', {surveyName: metadata['surveyName'], reportType: reportType})
            break
          case 'disable_public_link':
            reportType = activity.metadata['reportType'].split('_').join(' ')
            text = t('Disabled <i>{{surveyName}}</i> {{reportType}} link', {surveyName: metadata['surveyName'], reportType: reportType})
            break
          case 'regenerate_public_link':
            reportType = activity.metadata['reportType'].split('_').join(' ')
            text = t('Reset <i>{{surveyName}}</i> {{reportType}} link', {surveyName: metadata['surveyName'], reportType: reportType})
            break
          default:
            text = ''
            break
        }
        break
      case 'project':
        switch (activity.action) {
          case 'create_invite':
            text = t('Invited {{collaboratorEmail}} as {{role}}', {collaboratorEmail: metadata['collaboratorEmail'], role: metadata['role']})
            break
          case 'edit_invite':
            text = t('Updated invitation for {{collaboratorEmail}} from {{oldRole}} to {{newRole}}', {collaboratorEmail: metadata['collaboratorEmail'], oldRole: metadata['oldRole'], newRole: metadata['newRole']})
            break
          case 'delete_invite':
            text = t('Deleted invitation for {{collaboratorEmail}} as {{role}}', {collaboratorEmail: metadata['collaboratorEmail'], role: metadata['role']})
            break
          case 'edit_collaborator':
            text = t('Updated membership for {{collaboratorName}} from {{oldRole}} to {{newRole}}', {collaboratorName: metadata['collaboratorName'], oldRole: metadata['oldRole'], newRole: metadata['newRole']})
            break
          case 'remove_collaborator':
            text = t('Deleted {{role}} membership for {{collaboratorName}}', {collaboratorName: metadata['collaboratorName'], role: metadata['role']})
            break
          default:
            ''
            break
        }
        break
      default:
        text = ''
        break
    }
    return {__html: text}
  }

  render() {
    const { activity } = this.props
    return (
      <span dangerouslySetInnerHTML={this.text(activity)} />
    )
  }
}

ActivityDescription.propTypes = {
  t: PropTypes.func,
  activity: PropTypes.object
}

export default translate()(ActivityDescription)
