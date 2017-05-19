import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import Header from './Header'
import * as projectActions from '../../actions/project'

class HeaderContainer extends Component {
  componentDidMount() {
    const { projectId, surveyId, questionnaireId } = this.props.params

    if (projectId && (surveyId || questionnaireId)) {
      this.props.projectActions.fetchProject(projectId)
    }
  }

  render() {
    const { tabs, logout, user } = this.props
    let { project } = this.props
    const { projectId, surveyId, questionnaireId } = this.props.params

    let showProjectLink = true
    if (!project || (!surveyId && !questionnaireId)) {
      showProjectLink = false
    }

    if (projectId && !project) {
      // If there's a projectId and there's no project loaded
      // (it's still being loaded) we don't want to reset the body
      // class that came from the server.
    } else {
      let className = (project && project.colourScheme == 'better_data_for_health') ? 'bdfh' : ''
      $('body').removeClass('bdfh')
      $('body').addClass(className)
    }

    return (
      <Header tabs={tabs} logout={logout} user={user} showProjectLink={showProjectLink} showQuestionnairesLink={!!questionnaireId} project={project || null} />
    )
  }
}

HeaderContainer.propTypes = {
  projectActions: PropTypes.object.isRequired,
  params: PropTypes.object,
  project: PropTypes.object,
  tabs: PropTypes.node,
  logout: PropTypes.func.isRequired,
  user: PropTypes.string.isRequired
}

const mapStateToProps = (state, ownProps) => {
  return {
    params: ownProps.params,
    project: state.project.data
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HeaderContainer))
