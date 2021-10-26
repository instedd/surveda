import React, { PureComponent, PropTypes } from 'react'
import { Link } from 'react-router'
import { Card, Dropdown, DropdownItem } from '../ui'

import * as routes from '../../routes'

class FolderCard extends PureComponent {
  static propTypes = {
    projectId: PropTypes.number,
    id: PropTypes.number,
    name: PropTypes.string,
    t: PropTypes.func,
    onDelete: Function,
    onRename: Function,
    readOnly: PropTypes.bool
  }

  render() {
    const { name, projectId, id, t, onDelete, onRename, readOnly } = this.props
    const options = <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
      <DropdownItem className='dots'>
        <i className='material-icons'>more_vert</i>
      </DropdownItem>
      <DropdownItem>
        <a onClick={e => onRename(id, name)}><i className='material-icons'>edit</i>{t('Rename')}</a>
      </DropdownItem>
      <DropdownItem>
        <a onClick={e => onDelete(id)}><i className='material-icons'>delete</i>{t('Delete')}</a>
      </DropdownItem>
    </Dropdown>

    return (
      <Card>
        <div className='folder-card'>
          <div className='card-content'>
            <Link className='folder-card-title' to={routes.folder(projectId, id)}>
              <i className='material-icons'>folder</i>
              {name}
            </Link>
            {readOnly || options}
          </div>
        </div>
      </Card>
    )
  }
}
export default FolderCard
