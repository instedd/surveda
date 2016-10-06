import React from 'react'
import { Link } from 'react-router'
import TitleContainer from '../containers/TitleContainer'
import { Dropdown, DropdownItem, DropdownDivider } from './Dropdown'

export default ({ tabs, logout, user }) => (
  <header>
    <nav id='TopNav'>
      <div className='nav-wrapper'>
        <div className='row'>
          <div className='col s5 m4 offset-m1'>
            <ul>
              <li>
                <Link to='/projects' className=''> Projects
                </Link>
              </li>
              <li>
                <Link to='/channels' className=''> Channels
                </Link>
              </li>
            </ul>
          </div>
          <div className='col s7 m7'>
            <ul className='right'>
              <li>
                <Dropdown text={user}>
                  {/* <DropdownItem><Link to='#'>Settings</Link></DropdownItem> */}
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
    <TitleContainer/>
    {tabs}
  </header>
)
