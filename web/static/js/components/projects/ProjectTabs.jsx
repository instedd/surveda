import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '../shared'
import * as routes from '../../routes'

class ProjectTabs extends Component {
  render() {
    const { projectId } = this.props

    return (
      <Tabs>
        <TabLink to={routes.surveys(projectId)}>Surveys</TabLink>
        <TabLink to={routes.questionnaires(projectId)}>Questionnaires</TabLink>
      </Tabs>
    )
  }
}

ProjectTabs.propTypes = {
  projectId: PropTypes.number.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId)
})

export default connect(mapStateToProps)(ProjectTabs)
