import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import { Tooltip } from '.'
import { Button } from 'react-materialize'

export const AddButton = ({ text, linkPath, onClick, children, fab }) => {
  const icon = <i className='material-icons'>add</i>

  let link
  if (fab) {
    return (
      <Button
        floating
        fab={{ direction: 'top', hoverEnabled: true }}
        icon="add"
        className="btn-floating btn-large waves-effect waves-light right mtop green btn-icon-grey vertical"
      >
        { children }
      </Button>
    )
  } else if (linkPath) {
    link = (
      <Link className='btn-floating btn-large waves-effect waves-light green right mbottom' to={linkPath}>
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
  children: PropTypes.node,
  fab: PropTypes.boolean
}
