import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '.'

class ProjectTabs extends Component {
  render() {
    const { projectId } = this.props

    return (
      <nav id="BottomNav">
        <div className="nav-wrapper">
          <div className="row">
            <div className="col s12">
              <Tabs>
                <TabLink to={`/projects/${projectId}/surveys`} >Surveys</TabLink>
                <TabLink to={`/projects/${projectId}/questionnaires`} >Questionnaires</TabLink>
                <TabLink to='#' >Resources</TabLink>
                <TabLink to='#' >Respondents</TabLink>
                <TabLink to='#' >Collaborators</TabLink>
              </Tabs>
            </div>
          </div>
        </div>
      </nav>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
  }
}

export default connect(mapStateToProps)(ProjectTabs);
