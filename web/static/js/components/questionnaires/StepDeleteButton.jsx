// @flow
import React, { Component } from 'react'

type Props = {
  onDelete: Function
};

class StepDeleteButton extends Component {
  props: Props

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
          DELETE
        </a>
      </div>
    </li>)
  }
}

export default StepDeleteButton
