import React from 'react'
import { Link } from 'react-router'

export default ({ icon, title, linkPath, onClick, children }) => (
  <div className="empty_page">
    <i className="material-icons">{icon}</i>
    <h5>{title}</h5>
    { linkPath ?
      <Link to={linkPath}>Create one</Link>
    :
      onClick ?
        <a href='#' onClick={ onClick }>
          Create one
        </a>
      :
        children
    }
  </div>
)
