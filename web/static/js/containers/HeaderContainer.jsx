import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import TitleContainer from './TitleContainer'
import { Dropdown, DropdownItem, DropdownDivider } from '../components/Dropdown'
import Header from '../components/Header'
import * as projectActions from '../actions/projects'

class HeaderContainer extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    const { projectId } = this.props.params

    if (projectId) {
      dispatch(projectActions.fetchProjectIfNeeded(projectId))
    }
  }

  render () {
    const { tabs, logout, user, project } = this.props
    return (
      <Header tabs={tabs} logout={logout} user={user} project={project || null} />
    )
  }
}

const findById = (id, col) => {
  if (col) {
    return col[id]
  } else {
    return undefined
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    params: ownProps.params,
    project: findById(ownProps.params.projectId, state.projects),
  }
}

export default withRouter(connect(mapStateToProps)(HeaderContainer))
