// @flow

type ProviderConfig = {
  friendlyName: string,
  baseUrl: string
}

type Config = {
  nuntium: ProviderConfig[],
  verboice: ProviderConfig[],
  available_languages_for_numbers: string[]
};

const defaultConfig = {
  available_languages_for_numbers: ['en'],
  user_settings: {
    language: 'en'
  },
  nuntium: [],
  verboice: []
}

export const config: Config = window.appConfig || defaultConfig
