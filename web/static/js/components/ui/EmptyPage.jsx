import React, { PropTypes } from 'react'
import { Link } from 'react-router'

export const EmptyPage = ({ icon, title, linkPath, onClick, children }) => {
  let link
  if (linkPath) {
    link = <Link to={linkPath}>Create one</Link>
  } else if (onClick) {
    link = <a href='#' onClick={onClick}>Create one</a>
  } else {
    link = children
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
  children: PropTypes.node
}
