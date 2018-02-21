import React, { PropTypes } from 'react'
import { Link } from 'react-router'

export const EmptyPage = ({ icon, title, linkPath, onClick, children, readOnly }) => {
  let link
  if (!readOnly) {
    if (linkPath) {
      link = <Link to={linkPath}>Create one</Link>
    } else if (onClick) {
      link = <a href='#' className='green-text' onClick={onClick}><h5>Create one</h5></a>
    } else {
      link = children
    }
  } else {
    link = null
  }

  return (
    <div className='empty_page'>
      <i className='material-icons'>{icon}</i>
      <h5>{title}</h5>
      {link}
    </div>
  )
}

EmptyPage.propTypes = {
  icon: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  linkPath: PropTypes.string,
  onClick: PropTypes.func,
  children: PropTypes.node,
  readOnly: PropTypes.bool
}
