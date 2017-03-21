import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '../ui'
import * as routes from '../../routes'
import ColourSchemeModal from './ColourSchemeModal'

class ProjectTabs extends Component {
  openColorSchemePopup(e) {
    $('#colourSchemeModal').modal('open')
  }

  render() {
    const { projectId } = this.props

    let more = (
      <div className='col'>
        <a id='project-options-dropdown-trigger' className='dropdown-button' href='#' data-activates='project-options-dropdown'><i className='material-icons grey-text' style={{'height': '100%', 'line-height': '32px'}}>more_vert</i></a>
      </div>
    )

    return (
      <div>
        <Tabs id='project_tabs' more={more}>
          <TabLink tabId='project_tabs' to={routes.surveyIndex(projectId)}>Surveys</TabLink>
          <TabLink tabId='project_tabs' to={routes.questionnaireIndex(projectId)}>Questionnaires</TabLink>
          <TabLink tabId='project_tabs' to={routes.collaboratorIndex(projectId)}>Collaborators</TabLink>
        </Tabs>
        <ul id='project-options-dropdown' className='dropdown-content'>
          <li><a onClick={e => this.openColorSchemePopup(e)}><i className='material-icons'>palette</i></a></li>
        </ul>
        <ColourSchemeModal modalId='colourSchemeModal' />
      </div>
    )
  }

  componentDidMount() {
    $('project-options-dropdown-trigger').dropdown()
  }
}

ProjectTabs.propTypes = {
  projectId: PropTypes.any.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId
})

export default connect(mapStateToProps)(ProjectTabs)
