import * as guisso from '../guisso'

export const GUISSO_TOKEN = 'GUISSO_TOKEN';

export const obtainToken = (guissoConfig) => {
  return (dispatch, getState) => {
    const existingToken = getState().guisso[guissoConfig.appId];
    if (existingToken) {
      return Promise.resolve(existingToken);
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
