import * as guisso from '../guisso'

export const GUISSO_TOKEN = 'GUISSO_TOKEN';

export const obtainToken = (guissoConfig) => {
  return (dispatch, getState) => {
    const token = getState().guisso[guissoConfig.appId];
    if (token) {
      return Promise.resolve(token);
    }

    return guisso.obtainToken(guissoConfig).then(token => {
      dispatch({
        type: GUISSO_TOKEN,
        app: guissoConfig.appId,
        token
      });
      return token
    });
  }
}
