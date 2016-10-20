import React from 'react'

export default ({ property, text, sortBy, sortAsc, onClick }) => {
  const clickHandler = (e) => {
    e.preventDefault()
    e.stopPropagation()
    onClick(property)
  }

  let arrow
  if (property === sortBy) {
    if (sortAsc) {
      arrow = <i className='material-icons'>arrow_upward</i>
    } else {
      arrow = <i className='material-icons'>arrow_downward</i>
    }
  } else {
    arrow = ''
  }

  return (
    <th>
      {arrow}
      <a href='#!' onClick={clickHandler}>{text}</a>
    </th>
  )
}
