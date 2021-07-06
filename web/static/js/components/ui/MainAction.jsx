// @flow
import React, { Component } from 'react'
import { Button } from 'react-materialize'
import { Tooltip } from './Tooltip'

type BaseActionProps = {
  icon: string,
  text: string
}

type ActionProps = BaseActionProps & {
  onClick: Function
}

export class Action extends Component<ActionProps> {
  render = () => {
    const { icon, text, onClick } = this.props
    return (
      <li>
        <Button
          onClick={() => onClick()}
          className='btn-floating btn-small waves-effect waves-light right mbottom white black-text'
        >
          <Tooltip text={text} position='left'>
            <i className='material-icons black-text'>{icon}</i>
          </Tooltip>
        </Button>
      </li>
    )
  }
}

type MainActionProps = BaseActionProps & {
  onClick?: Function,
  children?: any, // Array<Action>
  className?: String
}

export class MainAction extends Component<MainActionProps> {
  render = () => {
    const { icon, text, onClick, children, className } = this.props
    return (
      <div className='fixed-action-btn click-to-toggle'>
        <a
          className='btn-floating btn-large waves-effect waves-light green right mtop direction-bottom'
          onClick={() => {
            if (onClick) onClick()
          }}
        >
          <Tooltip text={text} position='left'>
            <i className='material-icons'>{icon}</i>
          </Tooltip>
        </a>
        {children ? <ul className={className}>{children}</ul> : null}
      </div>
    )
  }
}
