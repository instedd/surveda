import React, { Component, PropTypes } from 'react'

class ChoiceEditor extends Component {
  render() {
    const { choice, onDelete } = this.props

    return (
      <tr>
        <td>
          {choice.value}
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
  choice: PropTypes.object
}

export default ChoiceEditor
