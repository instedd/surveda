import React from 'react'
import { Tooltip } from '../components/Tooltip'
import { Link } from 'react-router'

export default ({ text, linkPath, onClick }) => {
  const icon = <i className="material-icons">add</i>

  return (
    <Tooltip text={text}>
      {
        linkPath ?
          <Link className="btn-floating btn-large waves-effect waves-light green right mtop" to={ linkPath }>
            { icon }
          </Link>
        :
          onClick ?
            <a className="btn-floating btn-large waves-effect waves-light green right mtop" href="#" onClick={ onClick }>
              { icon }
            </a>
          :
            children
        }
    </Tooltip>
  )
}
