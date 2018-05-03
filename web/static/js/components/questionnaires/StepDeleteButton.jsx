// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  onDelete: Function,
  t: Function
};

class StepDeleteButton extends Component<Props> {
  delete(e: any) {
    e.preventDefault()
    const { onDelete } = this.props
    onDelete()
  }

  render() {
    return (<li className='collection-item' key='delete_button'>
      <div className='row'>
        <a href='#!'
          className='right'
          onClick={(e) => this.delete(e)}>
          {this.props.t('DELETE')}
        </a>
      </div>
    </li>)
  }
}

export default translate()(StepDeleteButton)
