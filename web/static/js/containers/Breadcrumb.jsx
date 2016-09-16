import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import Breadcrumbs, { combineResolvers, key, resolver } from 'react-router-breadcrumbs'
import * as projectActions from '../actions/projects'
import * as surveyActions from '../actions/surveys'
import * as questionnaireActions from '../actions/questionnaires'

class Breadcrumb extends Component {
  componentDidMount() {
    const {
      dispatch,
      projectId,
      project,
      surveyId,
      survey,
      questionnaireId,
      questionnaire
    } = this.props

    // Fetch project if it's still not in context 
    if (projectId && (project === undefined)) {
      dispatch(projectActions.fetchProject(projectId))
    }

    if (projectId && surveyId && (survey === undefined)) {
      dispatch(surveyActions.fetchSurvey(projectId, surveyId))
    }

    if (projectId && questionnaireId && (questionnaireId === undefined)) {
      dispatch(questionnaireActions.fetchQuestionnaire(projectId, questionnaireId))
    }
  }

  render() {
    const {
      project,
      projectId,
      survey,
      surveyId,
      questionnaire,
      questionnaireId,
      routes
    } = this.props

    const sep = (crumbElement, index, array) => ""

    const link = (link, key, text, index, routes) => {
      let hydratedLink = link

      if (projectId) {
        hydratedLink = hydratedLink.replace("projectId", projectId)
      }

      if (surveyId) {
        hydratedLink = hydratedLink.replace("surveyId", surveyId)
      }

      if (questionnaireId) {
        hydratedLink = hydratedLink.replace("questionnaireId", questionnaireId)
      }

      return <Link className="breadcrumb" to={hydratedLink} key={key}>{text}</Link>
    }

    const logo =
      <div key="0" className="logo">
        <img src='/images/logo.png' width='28px'/>
      </div>

    const prefix = [logo]

    const defaultResolver = (key, text, routePath, route) => key

    const entityResolver = (keyValue, text) => {
      if (keyValue === ':projectId') {
        if (project) {
          return project.name
        } else {
          return "Loading project..."
        }
      }

      if (keyValue === ':surveyId') {
        if (survey) {
          if (survey.name === "Untitled") {
            return "Untitled Survey"
          } else {
            return survey.name
          }
        } else {
          return "Loading survey..."
        }
      }

      if (keyValue === ':questionnaireId') {
        if (questionnaire) {
          if (questionnaire.name) {
            return questionnaire.name
          } else {
            return "Untitled Questionnaire"
          }
        } else {
          return "Loading questionnaire..."
        }
      }
    }

    const breadcrumbResolver = combineResolvers(entityResolver, defaultResolver)

    return (
      <nav id="Breadcrumb">
      <div className="nav-wrapper">
        <div className="row">
            <Breadcrumbs 
              routes={routes}
              resolver={breadcrumbResolver}
              createSeparator={sep}
              prefixElements = {prefix}
              createLink={link}/>
        </div>
      </div>
    </nav>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.projects[ownProps.params.projectId],
    surveyId: ownProps.params.surveyId,
    survey: state.surveys[ownProps.params.surveyId],
    questionnaireId: ownProps.params.questionnaireId,
    questionnaire: state.questionnaires[ownProps.params.questionnaireId]
  }
}

export default withRouter(connect(mapStateToProps)(Breadcrumb))