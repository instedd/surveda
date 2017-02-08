export const show = (disposition: Disposition) => {
  switch (disposition) {
    case null: return ''
    case 'completed': return 'Completed'
  }
}
