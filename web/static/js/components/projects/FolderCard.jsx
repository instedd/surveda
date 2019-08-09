import React, { PureComponent, PropTypes } from 'react'
import { Link } from 'react-router'
import { Card, Dropdown, DropdownItem } from '../ui'

import * as routes from '../../routes'

class FolderCard extends PureComponent {
  static propTypes = {
    projectId: PropTypes.number,
    id: PropTypes.number,
    name: PropTypes.string,
    t: PropTypes.func
  }
  render() {
    const { name, projectId, id, t } = this.props
    return (
      <div className='col s12 m6 l4'>
        <Card>
          <div className='folder-card'>
            <div className='card-content'>
              <Link className='folder-card-title' to={routes.folder(projectId, id)}>
                <i className='material-icons'>folder</i>
                {name}
              </Link>
              <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
                <DropdownItem className='dots'>
                  <i className='material-icons'>more_vert</i>
                </DropdownItem>
                <DropdownItem>
                  <a onClick={e => console.log('Delete me!')}><i className='material-icons'>folder</i>{t('Delete')}</a>
                </DropdownItem>
              </Dropdown>
            </div>
          </div>
        </Card>
      </div>
    )
  }
}
export default FolderCard
