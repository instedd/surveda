import React, { PropTypes } from 'react'

export const SortableHeader = ({ property, text, sortBy, sortAsc, onClick, className }) => {
  const clickHandler = (e) => {
    e.preventDefault()
    e.stopPropagation()
    onClick(property)
  }

  let arrow
  if (property == sortBy) {
    if (sortAsc) {
      arrow = <i className='material-icons'>arrow_upward</i>
    } else {
      arrow = <i className='material-icons'>arrow_downward</i>
    }
  } else {
    arrow = ''
  }

  return (
    <th className={`sortable ${className || ''}`}>
      {arrow}
      <a href='#!' onClick={clickHandler}>{text}</a>
    </th>
  )
}

SortableHeader.propTypes = {
  property: PropTypes.string.isRequired,
  text: PropTypes.string.isRequired,
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool,
  onClick: PropTypes.func.isRequired,
  className: PropTypes.string
}
