import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import { Tooltip } from '.'

const AddButton = ({ text, linkPath, onClick, children }) => {
  const icon = <i className='material-icons'>add</i>

  let link
  if (linkPath) {
    link = (
      <Link className='btn-floating btn-large waves-effect waves-light green right mtop' to={linkPath}>
        { icon }
      </Link>
    )
  } else if (onClick) {
    link = (
      <a className='btn-floating btn-large waves-effect waves-light green right mtop' href='#' onClick={onClick}>
        { icon }
      </a>
    )
  } else {
    link = children
  }

  return <Tooltip text={text}>{link}</Tooltip>
}

AddButton.propTypes = {
  text: PropTypes.string.isRequired,
  linkPath: PropTypes.string,
  onClick: PropTypes.func,
  children: PropTypes.node
}

export default AddButton
