import React, { PropTypes, Component } from 'react'
import uuid from 'node-uuid'
import classNames from 'classnames/bind'

export class InputWithLabel extends Component {
  static propTypes = {
    children: PropTypes.node,
    id: PropTypes.any,
    value: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number ]),
    label: PropTypes.string,
    errors: PropTypes.array
  }

  render() {
    let { children, id, value, label } = this.props
    id = do {
      if (id) {
        id
      } else {
        uuid.v4()
      }
    }

    var childrenWithProps = React.Children.map(children, function(child) {
      return React.cloneElement(child, { id: id, value: value })
    })

    let errorMessage = null

    // TODO: the error message in a label looks bad. Fix this style problem,
    // and then uncomment these lines:
    //
    // if (errors) {
    //   errorMessage = errors.join(', ')
    // }

    return (
      <div>
        {childrenWithProps}
        <label htmlFor={id} className={classNames({'active': (value != null && value !== '')})} data-error={errorMessage}>{label}</label>
      </div>
    )
  }
}
