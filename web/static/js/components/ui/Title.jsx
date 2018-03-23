import React, { PropTypes } from 'react'
import { Link } from 'react-router'
import Undo from './Undo'
import SaveStatus from '../layout/SaveStatus'
import { translate } from 'react-i18next'

export const Title = translate()(({ children, t }) => {
  const renderChildren = () => {
    if (typeof children == 'string') {
      return <a className='page-title'>{t(children)}</a>
    } else {
      return children
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
            <Undo />
            <SaveStatus />
          </div>
        </div>
      </div>
    </nav>
  )
})

Title.propTypes = {
  children: PropTypes.node,
  t: PropTypes.func
}
