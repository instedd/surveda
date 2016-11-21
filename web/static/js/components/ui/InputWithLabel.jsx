import React, { PropTypes, Component } from 'react'
import classNames from 'classnames/bind'

export class InputWithLabel extends Component {
  static propTypes = {
    children: PropTypes.node,
    id: PropTypes.string,
    value: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.number ]),
    label: PropTypes.string
  }

  render() {
    const { children, id, value, label } = this.props

    var childrenWithProps = React.Children.map(children, function(child) {
      return React.cloneElement(child, { id: id, value: value })
    })

    return (
      <div>
        {childrenWithProps}
        <label htmlFor={id} className={classNames({'active': value})}>{label}</label>
      </div>
    )
  }
}
