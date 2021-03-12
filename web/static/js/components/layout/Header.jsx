import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import TitleContainer from './TitleContainer'
import { UntitledIfEmpty, Dropdown, DropdownItem, DropdownDivider } from '../ui'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

const Header = ({ tabs, logout, user, project, surveyFolder, showProjectLink, showQuestionnairesLink, t, panelSurveyFolder }) => {
  let projectLink, questionnairesLink

  if (showProjectLink) {
    projectLink = (
      <li className='breadcrumb-item'>
        <Link to={routes.project(project.id)} className=''>
          <UntitledIfEmpty text={project.name} emptyText={t('Untitled project')} />
        </Link>
      </li>
    )
  }

  if (project && showQuestionnairesLink) {
    questionnairesLink = (
      <li className='breadcrumb-item'>
        <Link to={routes.questionnaireIndex(project.id)} className=''>{t('Questionnaires')}</Link>
      </li>
    )
  }

  const surveyFolderLink = surveyFolder
    ? (
      <li className='breadcrumb-item'>
        <Link to={routes.folder(surveyFolder.projectId, surveyFolder.id)} className=''>{surveyFolder.name}</Link>
      </li>
    )
    : null

  const panelSurveyFolderLink = panelSurveyFolder
    ? (
      <li className='breadcrumb-item'>
        <Link to={routes.panelSurveyFolder(panelSurveyFolder.projectId, panelSurveyFolder.id)} className=''>{panelSurveyFolder.name}</Link>
      </li>
    )
    : null

  return (
    <header>
      <nav id='TopNav'>
        <div className='nav-wrapper'>
          <div className='row'>
            <div className='col s12'>
              <ul className='breadcrumb-top'>
                <li>
                  <Link to={routes.projects} className=''>{t('Projects')}</Link>
                </li>
                { projectLink }
                { questionnairesLink }
                { surveyFolderLink }
                { panelSurveyFolderLink }
                <li className='channels-tab'>
                  <Link to={routes.channels}>{t('Channels')}</Link>
                </li>
              </ul>
              <ul className='right user-menu'>
                <li>
                  <Dropdown label={<div><span className='user-email'>{user}</span><i className='material-icons user-icon'>person</i></div>}>
                    <DropdownDivider />
                    <DropdownItem className='user-email-dropdown'>
                      <span>{user}</span>
                    </DropdownItem>
                    <DropdownItem>
                      <a href='/?explicit=true' target='_blank'>{t('About Surveda')}</a>
                    </DropdownItem>
                    <DropdownItem>
                      <a onClick={logout}>{t('Logout')}</a>
                    </DropdownItem>
                  </Dropdown>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </nav>
      <TitleContainer />
      {tabs}
    </header>
  )
}

Header.propTypes = {
  t: PropTypes.func,
  tabs: PropTypes.node,
  logout: PropTypes.func.isRequired,
  user: PropTypes.string.isRequired,
  project: PropTypes.object,
  surveyFolder: PropTypes.object,
  showProjectLink: PropTypes.bool,
  showQuestionnairesLink: PropTypes.bool,
  panelSurveyFolder: PropTypes.object
}

export default translate()(Header)
