import React, { PropTypes, Component } from 'react'
import uuidv4 from 'uuid/v4'
import classNames from 'classnames/bind'
import map from 'lodash/map'
import { translate } from 'react-i18next'

class InputWithLabelComponent extends Component {
  static propTypes = {
    t: PropTypes.func,
    children: PropTypes.node,
    id: PropTypes.any,
    value: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number ]),
    label: PropTypes.node,
    className: PropTypes.string,
    errors: PropTypes.array,
    readOnly: PropTypes.bool
  }

  render() {
    const { children, className, value, label, errors, readOnly, t } = this.props
    const id = this.props.id || uuidv4()

    var childrenWithProps = React.Children.map(children, function(child) {
      if (child) {
        if (readOnly) {
          return React.cloneElement(child, { id: id, value: value, disabled: readOnly })
        }
        return React.cloneElement(child, { id: id, value: value })
      } else {
        return null
      }
    })

    let errorMessage = null

    if (errors && errors.length > 0) {
      errorMessage = map(errors, (error) => t(...error)).join(', ')
    }

    return (
      <div className={className}>
        {childrenWithProps}
        <label htmlFor={id} className={classNames({'active': (value != null && value !== '')})} data-error={errorMessage}>{label}</label>
      </div>
    )
  }
}

export const InputWithLabel = translate()(InputWithLabelComponent)
