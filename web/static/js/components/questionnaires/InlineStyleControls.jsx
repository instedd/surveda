import React from 'react'
import StyleButton from './StyleButton'

class InlineStyleControls extends React.Component {
  INLINE_STYLES() {
    return ([
      {label: 'Bold', style: 'BOLD'},
      {label: 'Italic', style: 'ITALIC'},
      {label: 'Underline', style: 'UNDERLINE'},
      {label: 'Monospace', style: 'CODE'}
    ])
  }

  render() {
    var currentStyle = this.props.editorState.getCurrentInlineStyle()
    return (
      <div className='RichEditor-controls'>
        {this.INLINE_STYLES().map(type =>
          <StyleButton
            key={type.label}
            active={currentStyle.has(type.style)}
            label={type.label}
            onToggle={this.props.onToggle}
            style={type.style}
          />
        )}
      </div>
    )
  }
}

export default InlineStyleControls
