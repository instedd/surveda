import React, { PropTypes } from 'react'
import { Tooltip } from '.'
import classNames from 'classnames/bind'

export const RepeatButton = ({ text, onClick, disabled }) => {
  const icon = <i className='material-icons'>repeat_one</i>
  const baseClassNames = 'btn-floating btn-large right mtop primary-button'
  const button = disabled
  ? <a className={classNames(baseClassNames)} disabled>{icon}</a>
  : <a className={classNames(baseClassNames, 'waves-effect waves-light green')} href='#' onClick={onClick}>
    { icon }
  </a>

  return <Tooltip text={text}>{button}</Tooltip>
}

RepeatButton.propTypes = {
  text: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  disabled: PropTypes.bool
}
