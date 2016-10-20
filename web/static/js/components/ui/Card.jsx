import React, { PropTypes } from 'react'

export const Card = ({ children }) => (
  <div className='card'>
    { children }
  </div>
)

Card.propTypes = {
  children: PropTypes.node
}
