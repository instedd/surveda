import React, { PropTypes, Component } from 'react'
import 'materialize-autocomplete'

export class InputWithAutocomplete extends Component {

  languageAdded(language) {
    console.log(language)
  }

  render() {
    return (
      <div className='row'>
        <div className='col s12'>
          <div className='row'>
            <div className='input-field col s12'>
              <input type="text" ref='languageInput' id="singleInput" data-activates="singleDropdown" data-beloworigin="true" autocomplete="off" />
              <ul style={{background: '#eee'}} ref='languagesDropdown' id='singleDropdown' class="dropdown-content ac-dropdown"></ul>
              <label htmlFor='singleInput'>Autocomplete</label>
            </div>
          </div>
        </div>
      </div>

      // <div className='row'>
      //   <div className='col s12'>
      //     <div className='row'>
      //       <div className='input-field col s12'>
      //         <i className='material-icons prefix'>textsms</i>
      //         <input type='text' id='autocomplete-input' ref='languages' onChange={e => this.languageAdded(e)} />
      //         <label htmlFor='autocomplete-input'>Autocomplete</label>
      //       </div>
      //     </div>
      //   </div>
      // </div>
    )
  }

  componentDidMount() {
    // const iso6393 = require('iso-639-3')
    // let data = {}
    // iso6393.forEach(function(lang) {
    //   data[lang.name] = ''
    // })
    // $(this.refs.languages).autocomplete({
    //   data: data
    // })
    const languageAdded = this.languageAdded
    const languageInput = this.refs.languageInput
    const languagesDropdown = this.refs.languagesDropdown

    $(document).ready(function() {
      const single = $(languageInput).materialize_autocomplete({
         multiple: {
             enable: false
         },
         dropdown: {
             el: languagesDropdown,
             itemTemplate: '<li class="ac-item" data-id="<%= item.id %>" data-text=\'<%= item.text %>\'><a href="javascript:void(0)"><%= item.highlight %></a></li>'
         },
         onSelect: languageAdded
      })

      var resultCache = {
        'A': [
            {
                id: 'Abe',
                text: 'Sia \"Zirdzi\u0146\u0161\"',
                highlight: 'Sia \"Zirdzi\u0146\u0161\"'
            },
            {
                id: 'Ari',
                text: 'Ari',
                highlight: '<strong>A</strong>ri'
            }
        ],
        'B': [
            {
                id: 'Abe',
                text: 'Abe',
                highlight: '<strong>A</strong>be'
            },
            {
                id: 'Baz',
                text: 'Baz',
                highlight: '<strong>B</strong>az'
            }
        ],
        'BA': [
            {
                id: 'Baz',
                text: 'Baz',
                highlight: '<strong>Ba</strong>z'
            }
        ],
        'BAZ': [
            {
                id: 'Baz',
                text: 'Baz',
                highlight: '<strong>Baz</strong>'
            }
        ],
        'AB': [
            {
                id: 'Abe',
                text: 'Abe',
                highlight: '<strong>Ab</strong>e'
            }
        ],
        'ABE': [
            {
                id: 'Abe',
                text: 'Abe',
                highlight: '<strong>Abe</strong>'
            }
        ],
        'AR': [
            {
                id: 'Ari',
                text: 'Ari',
                highlight: '<strong>Ar</strong>i'
            }
        ],
        'ARI': [
            {
                id: 'Ari',
                text: 'Ari',
                highlight: '<strong>Ari</strong>'
            }
        ]
      };
      single.resultCache = resultCache
    })
  }
}
