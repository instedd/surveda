import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '../ui'
import * as routes from '../../routes'
import * as toggleColourScheme from '../../toggleColourScheme'

class ProjectTabs extends Component {
  render() {
    const { projectId } = this.props

    return (
      <div>
        <Tabs id='project_tabs'>
          <TabLink tabId='project_tabs' to={routes.surveyIndex(projectId)}>Surveys</TabLink>
          <TabLink tabId='project_tabs' to={routes.questionnaireIndex(projectId)}>Questionnaires</TabLink>
          <TabLink tabId='project_tabs' to={routes.collaboratorIndex(projectId)}>Collaborators</TabLink>
        </Tabs>
        <div onClick={() => toggleColourScheme.toggleDefault()}>
          Default Scheme
        </div>
        <div onClick={() => toggleColourScheme.toggleBetterDataForHealth()}>
          Better data for health
        </div>
      </div>
    )
  }
}

ProjectTabs.propTypes = {
  projectId: PropTypes.any.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId
})

export default connect(mapStateToProps)(ProjectTabs)
