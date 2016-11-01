import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import TitleContainer from './TitleContainer'
import { UntitledIfEmpty, Dropdown, DropdownItem, DropdownDivider } from '../ui'
import * as routes from '../../routes'

const Header = ({ tabs, logout, user, project }) => {
  let projectLink
  if (project) {
    projectLink = (
      <li>
        <Link to={routes.project(project.id)} className=''>
          <UntitledIfEmpty text={project.name} />
        </Link>
      </li>
    )
  }

  return (
    <header>
      <nav id='TopNav'>
        <div className='nav-wrapper'>
          <div className='row'>
            <div className='col s5 m6'>
              <ul>
                <li>
                  <Link to={routes.projects} className=''> Projects </Link>
                </li>
                { projectLink }
                <li>
                  <Link to={routes.channels} className=''> Channels </Link>
                </li>
              </ul>
            </div>
            <div className='col s8 m6'>
              <ul className='right'>
                <li>
                  <Dropdown label={user}>
                    <DropdownDivider />
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
  project: PropTypes.object
}

export default Header
