import React, { PropTypes } from 'react'

const Card = ({ children }) => (
  <div className='card'>
    { children }
  </div>
)

Card.propTypes = {
  children: PropTypes.node
}

export default Card
