import React, { Component, PropTypes } from 'react'

class ChoiceEditor extends Component {
  render() {
    const { choice, onValueClick, onDelete } = this.props

    return (
      <tr>
        <td>
          <div onClick={onValueClick}>{choice.value}</div>
        </td>
        <td>
          {choice.responses.join(', ')}
        </td>
        <td>
          <a href='#!' onClick={onDelete}><i className='material-icons'>delete</i></a>
        </td>
      </tr>
    )
  }
}

ChoiceEditor.propTypes = {
  onDelete: PropTypes.func,
  onValueClick: PropTypes.func,
  choice: PropTypes.object,
  editing: PropTypes.bool
}

export default ChoiceEditor
