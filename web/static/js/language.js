// @flow
import iso6393 from 'iso-639-3'

export function nameToCode(name: string): ?string {
  let match = iso6393.find(l => l.name == name)
  return match ? (match.iso6391 || match.iso6393) : null
}

export function codeToName(code: string): ?string {
  let match = iso6393.find(l => l.iso6391 == code || l.iso6393 == code)
  return match ? match.name : null
}
