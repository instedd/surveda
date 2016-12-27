// @flow
import iso6393 from 'iso-639-3'

export function nameToCode(name: string): string {
  return iso6393.find(l => l.name == name).iso6391
}

export function codeToName(code: string): string {
  return iso6393.find(l => l.iso6391 == code || l.iso6393 == code).name
}
