// @flow
import * as actions from '../../actions/channel'
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Autocomplete } from '../ui'
import 'materialize-autocomplete'
import { translate } from 'react-i18next'
import filter from 'lodash/filter'
import map from 'lodash/map'
import includes from 'lodash/includes'

type Props = {
  projects: IndexedList<Project>,
  selectedProjects: number[],
  dispatch: Function,
  t: Function,
};

type State = {
  editing: boolean
};

class AddProject extends Component {
  props: Props;
  state: State;

  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }
  }

  startEdit() {
    if (this.state.editing) return

    this.setState({editing: true})
  }

  endEdit(e) {
    if (this.refs.autocomplete.clickingAutocomplete) return

    this.setState({editing: false})
  }

  autocompleteGetData(value, callback) {
    const { projects, selectedProjects } = this.props
    const matchingOptions = filter(map(Object.keys(projects), (projectId) => ({
      id: parseInt(projectId),
      text: projects[projectId].name || 'Untitled project'
    })), ({id, text}) => (
      !includes(selectedProjects, id) && (
        (text).indexOf(value.toLowerCase()) !== -1 ||
        (text).toLowerCase().indexOf(value.toLowerCase()) !== -1
      )
    ))

    callback(value, matchingOptions)
  }

  autocompleteOnSelect(item) {
    const { dispatch } = this.props
    this.endEdit()
    dispatch(actions.shareWithProject(item.id))
    $(this.refs.projectInput).val('')
  }

  render() {
    const { t } = this.props
    if (!this.state.editing) {
      return (
        <a className='btn-icon-grey' onClick={e => this.startEdit(e)}>
          <span><i className='material-icons'>add</i></span>
          <span>{t('Add project')}</span>
        </a>
      )
    } else {
      return (
        <div className='input-field project-selection'>
          <input type='text' ref='projectInput' id='projectInput' autoComplete='off' className='autocomplete' placeholder={t('Start typing a project')} onBlur={e => this.endEdit(e)} />
          <Autocomplete
            getInput={() => this.refs.projectInput}
            getData={(value, callback) => this.autocompleteGetData(value, callback)}
            onSelect={(item) => this.autocompleteOnSelect(item)}
            showOnClick
            className='project-dropdown'
            ref='autocomplete'
            />
        </div>
      )
    }
  }

  componentDidUpdate() {
    if (this.refs.projectInput) {
      this.refs.projectInput.focus()
    }
  }
}

export default translate()(connect()(AddProject))
