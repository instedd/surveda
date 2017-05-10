import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import TitleContainer from './TitleContainer'
import { UntitledIfEmpty, Dropdown, DropdownItem, DropdownDivider } from '../ui'
import * as routes from '../../routes'

const Header = ({ tabs, logout, user, project, showProjectLink }) => {
  let projectLink

  if (showProjectLink) {
    projectLink = (
      <li className='breadcrumb-item'>
        <Link to={routes.project(project.id)} className=''>
          <UntitledIfEmpty text={project.name} entityName='project' />
        </Link>
      </li>
    )
  }

  return (
    <header>
      <nav id='TopNav'>
        <div className='nav-wrapper'>
          <div className='row'>
            <div className='col s12'>
              <ul className='breadcrumb-top'>
                <li>
                  <Link to={routes.projects} className=''> Projects </Link>
                </li>
                { projectLink }
                <li className='channels-tab'>
                  <Link to={routes.channels}> Channels </Link>
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
                      <a href='/?explicit=true' target='_blank'>About Surveda</a>
                    </DropdownItem>
                    <DropdownItem>
                      <a onClick={logout}>Logout</a>
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
  tabs: PropTypes.node,
  logout: PropTypes.func.isRequired,
  user: PropTypes.string.isRequired,
  project: PropTypes.object,
  showProjectLink: PropTypes.bool
}

export default Header
