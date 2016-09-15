import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '.'

class ProjectTabs extends Component {
  render() {
    const { projectId } = this.props

    return (
      <Tabs>
        <TabLink to={`/projects/${projectId}/surveys`}>Surveys</TabLink>
        <TabLink to={`/projects/${projectId}/questionnaires`} >Questionnaires</TabLink>
      </Tabs>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
})

export default connect(mapStateToProps)(ProjectTabs);
