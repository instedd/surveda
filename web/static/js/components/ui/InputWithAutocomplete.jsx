import React, { PropTypes, Component } from 'react'
// import classNames from 'classnames/bind'

export class InputWithAutocomplete extends Component {

  render() {
    const x = 1
    return (
      <div class="row">
        <div class="col s12">
          <div class="row">
            <div class="input-field col s12">
              <i class="material-icons prefix">textsms</i>
              <input type="text" id="autocomplete-input" class="autocomplete"></input>
              <label for="autocomplete-input">Autocomplete</label>
            </div>
          </div>
        </div>
      </div>
    )
  }

  componentDidMount(){
    $('input.autocomplete').autocomplete({
      data: {
        "Apple": null,
        "Microsoft": null,
        "Google": 'http://placehold.it/250x250'
      }
    });
  }

}
