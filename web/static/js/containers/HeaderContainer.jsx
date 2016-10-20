import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import TitleContainer from './TitleContainer'
import { Dropdown, DropdownItem, DropdownDivider } from '../components/Dropdown'
import Header from '../components/Header'
import * as projectAction from '../actions/project'

class HeaderContainer extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    const { projectId, surveyId, questionnaireId } = this.props.params

    if (projectId && (surveyId || questionnaireId)) {
      dispatch(projectAction.fetchProject(projectId))
    }
  }

  render() {
    const { tabs, logout, user } = this.props
    let { project } = this.props
    const { surveyId, questionnaireId } = this.props.params

    if (!surveyId && !questionnaireId) {
      project = null
    }

    return (
      <Header tabs={tabs} logout={logout} user={user} project={project || null} />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    params: ownProps.params,
    project: state.project.data
  }
}

export default withRouter(connect(mapStateToProps)(HeaderContainer))
