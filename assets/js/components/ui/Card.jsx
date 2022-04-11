import React, { PropTypes } from "react"
import classNames from "classnames/bind"

export const Card = ({ children, className }) => (
  <div className={classNames(className, { card: true })}>{children}</div>
)

Card.propTypes = {
  children: PropTypes.node,
  className: PropTypes.string,
}
