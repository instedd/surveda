import React, { PropTypes, Component } from 'react'
import uuidv4 from 'uuid/v4'
import classNames from 'classnames/bind'
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
    const { children, className, value, label, errors, readOnly } = this.props
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

    const hasErrors = errors && errors.length > 0
    const active = value != null && value !== ''

    const renderErrors = () => {
      const errorMessage = errors.join(', ')
      return <div className={classNames({'active': active, 'error': true})}>{errorMessage}</div>
    }

    const renderLabel = () => <label htmlFor={id} className={classNames({'active': active})}>{label}</label>

    return (
      <div className={className}>
        {hasErrors ? renderLabel() : null}
        {childrenWithProps}
        {hasErrors ? renderErrors() : renderLabel()}
      </div>
    )
  }
}

export const InputWithLabel = translate()(InputWithLabelComponent)
