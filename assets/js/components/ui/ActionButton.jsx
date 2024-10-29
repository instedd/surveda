import React, { PropTypes } from "react"
import { Link } from "react-router"
import { Tooltip } from "."

export const ActionButton = ({ text, linkPath, onClick, children, icon = "add", color = "green" }) => {
  const materialIcon = <i className="material-icons">{icon}</i>

  let link
  if (linkPath) {
    link = (
      <Link
        className={`btn-floating btn-large waves-effect waves-light ${color} right mbottom`}
        to={linkPath}
      >
        {materialIcon}
      </Link>
    )
  } else if (onClick) {
    link = (
      <a
        className={`btn-floating btn-large waves-effect waves-light ${color} right mtop`}
        href="#"
        onClick={onClick}
      >
        {materialIcon}
      </a>
    )
  } else {
    link = children
  }

  return <Tooltip text={text}>{link}</Tooltip>
}

ActionButton.propTypes = {
  text: PropTypes.string.isRequired,
  linkPath: PropTypes.string,
  onClick: PropTypes.func,
  children: PropTypes.node,
  icon: PropTypes.string,
  color: PropTypes.string,
}
