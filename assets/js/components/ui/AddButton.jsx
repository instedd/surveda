import React, { PropTypes } from "react"
import { Link } from "react-router"
import { ActionButton, Tooltip } from "."

export const AddButton = ({ text, linkPath, onClick, children }) => {
  return ActionButton({ text, linkPath, onClick, children, iconName: "add" })
}

AddButton.propTypes = {
  text: PropTypes.string.isRequired,
  linkPath: PropTypes.string,
  onClick: PropTypes.func,
  children: PropTypes.node,
}
