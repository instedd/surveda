import React from 'react'
import { Link } from 'react-router'
import { Dropdown, DropdownItem, DropdownDivider } from './Dropdown'

export default ({tabs}) => (
  <header>
    <nav id="TopNav">
      <div className="nav-wrapper">
        <div className="row">
          <div className="col s5 offset-s1">
            <ul>
              <li><Link to='/projects' className="">Projects</Link></li>
              <li><Link to='/channels' className="">Channels</Link></li>
            </ul>
          </div>
          <div className="col s6">
            <ul className="right">
              <li>
                <Dropdown text="Robert Stevenson">
                  <DropdownItem><Link to='/settings'>Settings</Link></DropdownItem>
                  <DropdownDivider />
                  <DropdownItem><Link to='/logout'>Logout</Link></DropdownItem>
                </Dropdown>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </nav>
    <nav id="Breadcrumb">
      <div className="nav-wrapper">
        <div className="row">
          <div className="col s12">
            <div className="logo">
              <img src='/images/logo.png' width='28px'/>
            </div>
            <a href="#!" className="breadcrumb">My Projects</a>
            <Link to='/projects' className="breadcrumb">projects</Link>
          </div>
      </div>
      </div>
    </nav>
    {tabs}
  </header>
)
