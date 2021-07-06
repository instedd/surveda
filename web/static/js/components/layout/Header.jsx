import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import TitleContainer from './TitleContainer'
import { UntitledIfEmpty, Dropdown, DropdownItem, DropdownDivider } from '../ui'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

const Header = ({ tabs, logout, user, project, folder, showProjectLink, showQuestionnairesLink, t, panelSurvey }) => {
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

  const folderLink = folder
    ? (
      <li className='breadcrumb-item'>
        <Link to={routes.folder(folder.projectId, folder.id)} className=''>{folder.name}</Link>
      </li>
    )
    : null

  const panelSurveyLink = panelSurvey
    ? (
      <li className='breadcrumb-item'>
        <Link to={routes.panelSurvey(panelSurvey.projectId, panelSurvey.id)} className=''>{panelSurvey.name || t('Untitled survey')}</Link>
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
                { folderLink }
                { panelSurveyLink }
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
  folder: PropTypes.object,
  showProjectLink: PropTypes.bool,
  showQuestionnairesLink: PropTypes.bool,
  panelSurvey: PropTypes.object
}

export default translate()(Header)
