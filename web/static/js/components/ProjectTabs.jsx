import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '.'
import * as routes from '../routes'

class ProjectTabs extends Component {
  render() {
    const { projectId } = this.props

    return (
      <Tabs>
        <TabLink to={routes.surveys(projectId)}>Surveys</TabLink>
        <TabLink to={routes.questionnaires(projectId)} >Questionnaires</TabLink>
      </Tabs>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId
})

export default connect(mapStateToProps)(ProjectTabs)
