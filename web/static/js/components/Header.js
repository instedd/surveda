import React from 'react'
import { Link } from 'react-router'

export default () => (
  <nav className="navbar navbar-default">
    <ul className="nav navbar-nav">
      <li><Link to='/projects'>projects</Link></li>
    </ul>
  </nav>
)
