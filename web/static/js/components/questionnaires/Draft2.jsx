import React from 'react'
// import {Editor, EditorState, RichUtils} from 'draft-js'
import {
  RichUtils,
  convertFromRaw,
  convertToRaw,
  CompositeDecorator,
  ContentState,
  Editor,
  EditorState
} from 'draft-js'

class DraftSecondExample extends React.Component {
  constructor(props) {
    const rawContent = {
      blocks: [
        {
          text: (
            'This is an "immutable" entity: Superman. Deleting any ' +
            'characters will delete the entire entity. Adding characters ' +
            'will remove the entity from the range.'
          ),
          type: 'unstyled',
          entityRanges: [{offset: 31, length: 8, key: 'first'}]
        },
        {
          text: '',
          type: 'unstyled'
        },
        {
          text: (
            'This is a "mutable" entity: Batman. Characters may be added ' +
            'and removed.'
          ),
          type: 'unstyled',
          entityRanges: [{offset: 28, length: 6, key: 'second'}]
        },
        {
          text: '',
          type: 'unstyled'
        },
        {
          text: (
            'This is a "segmented" entity: Green Lantern. Deleting any ' +
            'characters will delete the current "segment" from the range. ' +
            'Adding characters will remove the entire entity from the range.'
          ),
          type: 'unstyled',
          entityRanges: [{offset: 30, length: 13, key: 'third'}]
        }
      ],
      entityMap: {
        first: {
          type: 'TOKEN',
          mutability: 'IMMUTABLE'
        },
        second: {
          type: 'TOKEN',
          mutability: 'MUTABLE'
        },
        third: {
          type: 'TOKEN',
          mutability: 'SEGMENTED'
        }
      }
    }

    super(props)
    const decorator = new CompositeDecorator([
      {
        strategy: this.getEntityStrategy('IMMUTABLE'),
        component: this.TokenSpan
      },
      {
        strategy: this.getEntityStrategy('MUTABLE'),
        component: this.TokenSpan
      },
      {
        strategy: this.getEntityStrategy('SEGMENTED'),
        component: this.TokenSpan
      }
    ])

    const blocks = convertFromRaw(rawContent)

    this.state = {
      editorState: EditorState.createWithContent(blocks, decorator)
    }

    this.focus = () => this.refs.editor.focus()
    this.onChange = (editorState) => this.setState({editorState})
    this.logState = () => {
      const content = this.state.editorState.getCurrentContent()
      console.log(convertToRaw(content))
    }
  }

  // getDecoratedStyle(mutability) {
  //   switch (mutability) {
  //     case 'IMMUTABLE': return this.styles().immutable
  //     case 'MUTABLE': return this.styles().mutable
  //     case 'SEGMENTED': return this.styles().segmented
  //     default: return null
  //   }
  // }

  TokenSpan(props) {
    const getDecoratedStyle = (mutability) => {
      const styles = {
        root: {
          fontFamily: '\'Helvetica\', sans-serif',
          padding: 20,
          width: 600
        },
        editor: {
          border: '1px solid #ccc',
          cursor: 'text',
          minHeight: 80,
          padding: 10
        },
        button: {
          marginTop: 10,
          textAlign: 'center'
        },
        immutable: {
          backgroundColor: 'rgba(0, 0, 0, 0.2)',
          padding: '2px 0'
        },
        mutable: {
          backgroundColor: 'rgba(204, 204, 255, 1.0)',
          padding: '2px 0'
        },
        segmented: {
          backgroundColor: 'rgba(248, 222, 126, 1.0)',
          padding: '2px 0'
        }
      }
      switch (mutability) {
        case 'IMMUTABLE': return styles.immutable
        case 'MUTABLE': return styles.mutable
        case 'SEGMENTED': return styles.segmented
        default: return null
      }
    }

    const style = getDecoratedStyle(
      props.contentState.getEntity(props.entityKey).getMutability()
    )
    return (
      <span data-offset-key={props.offsetkey} style={style}>
        {props.children}
      </span>
    )
  }

  getEntityStrategy(mutability) {
    return function(contentBlock, callback, contentState) {
      contentBlock.findEntityRanges(
        (character) => {
          const entityKey = character.getEntity()
          if (entityKey === null) {
            return false
          }
          return contentState.getEntity(entityKey).getMutability() === mutability
        },
       callback
     )
    }
  }

  styles() {
    return ({
      root: {
        fontFamily: '\'Helvetica\', sans-serif',
        padding: 20,
        width: 600
      },
      editor: {
        border: '1px solid #ccc',
        cursor: 'text',
        minHeight: 80,
        padding: 10
      },
      button: {
        marginTop: 10,
        textAlign: 'center'
      },
      immutable: {
        backgroundColor: 'rgba(0, 0, 0, 0.2)',
        padding: '2px 0'
      },
      mutable: {
        backgroundColor: 'rgba(204, 204, 255, 1.0)',
        padding: '2px 0'
      },
      segmented: {
        backgroundColor: 'rgba(248, 222, 126, 1.0)',
        padding: '2px 0'
      }
    })
  }

  Link(props) {
    const style = {
      color: '#3b5998',
      textDecoration: 'underline'
    }
    const {url} = props.contentState.getEntity(props.entityKey).getData()
    return (
      <a href={url} style={style}>
        {props.children}
      </a>
    )
  }

  findLinkEntities(contentBlock, callback, contentState) {
    contentBlock.findEntityRanges(
      (character) => {
        const entityKey = character.getEntity()
        return (
          entityKey !== null &&
          contentState.getEntity(entityKey).getType() === 'LINK'
        )
      },
      callback
    )
  }

  _promptForLink(e) {
    e.preventDefault()
    const {editorState} = this.state
    const selection = editorState.getSelection()
    if (!selection.isCollapsed()) {
      const contentState = editorState.getCurrentContent()
      const startKey = editorState.getSelection().getStartKey()
      const startOffset = editorState.getSelection().getStartOffset()
      const blockWithLinkAtBeginning = contentState.getBlockForKey(startKey)
      const linkKey = blockWithLinkAtBeginning.getEntityAt(startOffset)

      let url = ''
      if (linkKey) {
        const linkInstance = contentState.getEntity(linkKey)
        url = linkInstance.getData().url
      }

      this.setState({
        showURLInput: true,
        urlValue: url
      }, () => {
        setTimeout(() => this.refs.url.focus(), 0)
      })
    }
  }

  _confirmLink(e) {
    e.preventDefault()
    const {editorState, urlValue} = this.state
    const contentState = editorState.getCurrentContent()
    const contentStateWithEntity = contentState.createEntity(
      'LINK',
      'MUTABLE',
      {url: urlValue}
    )
    const entityKey = contentStateWithEntity.getLastCreatedEntityKey()
    const newEditorState = EditorState.set(editorState, { currentContent: contentStateWithEntity })
    this.setState({
      editorState: RichUtils.toggleLink(
        newEditorState,
        newEditorState.getSelection(),
        entityKey
      ),
      showURLInput: false,
      urlValue: ''
    }, () => {
      setTimeout(() => this.refs.editor.focus(), 0)
    })
  }

  _onLinkInputKeyDown(e) {
    if (e.which === 13) {
      this._confirmLink(e)
    }
  }

  _removeLink(e) {
    e.preventDefault()
    const {editorState} = this.state
    const selection = editorState.getSelection()
    if (!selection.isCollapsed()) {
      this.setState({
        editorState: RichUtils.toggleLink(editorState, selection, null)
      })
    }
  }

  render() {
    return (
      <div style={this.styles().root}>
        <div style={this.styles().editor} onClick={this.focus}>
          <Editor
            editorState={this.state.editorState}
            onChange={this.onChange}
            placeholder='Enter some text...'
            ref='editor'
          />
        </div>
        <input
          onClick={this.styles().logState}
          style={this.styles().button}
          type='button'
          value='Log State'
        />
      </div>
    )
  }
}

export default DraftSecondExample
