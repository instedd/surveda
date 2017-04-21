import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink, Dropdown, DropdownItem} from '../ui'
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
        <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
          <DropdownItem className='dots'>
            <i className='material-icons'>more_vert</i>
          </DropdownItem>
          <DropdownItem>
            <a onClick={e => this.openColorSchemePopup(e)}><i className='material-icons'>palette</i>Change color scheme</a>
          </DropdownItem>
        </Dropdown>
      </div>
    )

    return (
      <div>
        <Tabs id='project_tabs' more={more}>
          <TabLink tabId='project_tabs' to={routes.surveyIndex(projectId)}>Surveys</TabLink>
          <TabLink tabId='project_tabs' to={routes.questionnaireIndex(projectId)}>Questionnaires</TabLink>
          <TabLink tabId='project_tabs' to={routes.collaboratorIndex(projectId)}>Collaborators</TabLink>
        </Tabs>
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
