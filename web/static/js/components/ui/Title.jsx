import React, { PropTypes } from 'react'
import { Link } from 'react-router'

const Title = ({ children }) => {
  const renderChildren = () => {
    if (typeof children == 'string') {
      return <a className='page-title'>{children}</a>
    } else {
      return children
    }
  }

  return (
    <nav id='MainNav'>
      <div className='nav-wrapper'>
        <div className='row'>
          <div className='col s12'>
            <div className='logo'><Link to='/'><img src='/images/logo.png' width='28px' /></Link></div>
            {renderChildren()}
          </div>
        </div>
      </div>
    </nav>
  )
}

Title.propTypes = {
  children: PropTypes.node
}

export default Title
