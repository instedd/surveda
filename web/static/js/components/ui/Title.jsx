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
                <svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlnsXlink='http://www.w3.org/1999/xlink' width='60px' height='60px'>
                  <rect x='26' y='14' transform='matrix(-1 -4.183688e-11 4.183688e-11 -1 60 56)' className='st0' width='8' height='28' />
                  <rect x='36' y='23' className='st1' width='8' height='19' />
                  <polygon className='st2' points='36,23 44,31 44,42 36,42 ' />
                  <rect x='16' y='33' className='st3' width='8' height='9' />
                  <path className='st4' d='M60,30c0,16.6-13.4,30-30,30S0,46.6,0,30S13.4,0,30,0S60,13.4,60,30z M30,1C14,1,1,14,1,30s13,29,29,29
                    s29-13,29-29S46,1,30,1z' />
                </svg>
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
