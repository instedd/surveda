import React, { PureComponent, PropTypes } from 'react'
import { Link } from 'react-router'
import { Card } from '../ui'

import * as routes from '../../routes'

class FolderCard extends PureComponent {
  static propTypes = {
    projectId: PropTypes.number,
    id: PropTypes.number,
    name: PropTypes.string
  }
  render() {
    const { name, projectId, id } = this.props
    return (
      <div className='col s12 m6 l4'>
        <Link className='folder-card' to={routes.folder(projectId, id)}>
          <Card>
            <div className='card-content black-text valign-wrapper'>
              <i className='material-icons'>folder</i>
              {name}
            </div>
          </Card>
        </Link>
      </div>
    )
  }
}
export default FolderCard
