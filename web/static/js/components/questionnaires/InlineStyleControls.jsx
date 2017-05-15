import React, {PropTypes} from 'react'
import StyleButton from './StyleButton'

class InlineStyleControls extends React.Component {
  INLINE_STYLES() {
    return ([
      {label: 'Bold', style: 'BOLD', icon: 'format_bold'},
      {label: 'Italic', style: 'ITALIC', icon: 'format_italic'},
      {label: 'Underline', style: 'UNDERLINE', icon: 'format_underline'}
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
            icon={type.icon}
            onToggle={this.props.onToggle}
            style={type.style}
          />
        )}
      </div>
    )
  }
}

InlineStyleControls.propTypes = {
  onToggle: PropTypes.func,
  editorState: PropTypes.object
}

export default InlineStyleControls
