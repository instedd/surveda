import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import SaveStatus from '../layout/SaveStatus'
import { translate } from 'react-i18next'

const Title = ({ children, t }) => {
  const renderChildren = () => {
    if (typeof children == 'string') {
      return <a className='page-title'>{t(children)}</a>
    } else {
      return t(children)
    }
  }

  return (
    <nav id='MainNav'>
      <div className='nav-wrapper'>
        <div className='row'>
          <div className='col s8'>
            <div className='logo'>
              <Link className='logo-container' to='/' />
            </div>
            {renderChildren()}
          </div>
          <div className='col s4'>
            <SaveStatus />
          </div>
        </div>
      </div>
    </nav>
  )
}

Title.propTypes = {
  children: PropTypes.node,
  t: PropTypes.func
}

export default translate()(Title)
