import React from 'react'
import { Link } from 'react-router'
import Breadcrumb from '../containers/Breadcrumb'
import { Dropdown, DropdownItem, DropdownDivider } from './Dropdown'
import { config } from '../config'
import 'isomorphic-fetch'

export default ({ tabs }) => (
  <header>
    <nav id="TopNav">
      <div className="nav-wrapper">
        <div className="row">
          <div className="col s5 m4 offset-m1">
            <ul>
              <li><Link to='/projects' className="">Projects</Link></li>
              <li><Link to='/channels' className="">Channels</Link></li>
            </ul>
          </div>
          <div className="col s7 m7">
            <ul className="right">
              <li>
                <Dropdown text={config.user}>
                  <DropdownItem><Link to='/settings'>Settings</Link></DropdownItem>
                  <DropdownDivider />
                  <DropdownItem><a onClick={logout}>Logout</a></DropdownItem>
                </Dropdown>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </nav>
    <Breadcrumb/>
    {tabs}
  </header>
)

const logout = () => {
  fetch("/logout", {
    method: 'DELETE',
    credentials: 'same-origin'
  }).then(() => window.location.reload())
}