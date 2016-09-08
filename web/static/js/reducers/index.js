import { combineReducers } from 'redux';
import { routerReducer as routing } from 'react-router-redux';
import projects from './projects';
import surveys from './surveys';
import questionnaires from './questionnaires';
import channels from './channels';

export default combineReducers({
  routing,
  projects,
  surveys,
  questionnaires,
  channels
});
