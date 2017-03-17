import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import SaveStatus from '../layout/SaveStatus'

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
          <div className='col s9'>
            <div className='logo'>
              <Link to='/'>
                <div className='logo-container' />
              </Link>
            </div>
            {renderChildren()}
          </div>
          <div className='col s3'>
            <SaveStatus />
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
