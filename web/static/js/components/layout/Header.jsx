import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import TitleContainer from './TitleContainer'
import { UntitledIfEmpty, Dropdown, DropdownItem, DropdownDivider } from '../ui'
import * as routes from '../../routes'
import { toggleColourScheme } from '../../toggleColourScheme'

const Header = ({ tabs, logout, user, project, showProjectLink }) => {
  let projectLink
  let scheme = project ? project.colourScheme : 'default'

  if (showProjectLink) {
    projectLink = (
      <li className='breadcrumb-item'>
        <Link to={routes.project(project.id)} className=''>
          <UntitledIfEmpty text={project.name} entityName='project' />
        </Link>
      </li>
    )
  }
  toggleColourScheme(scheme)

  return (
    <header className={scheme}>
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
  showProjectLink: PropTypes.boolean
}

export default Header
