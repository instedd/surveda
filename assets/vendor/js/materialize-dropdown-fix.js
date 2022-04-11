// This is a workaround until this PR is released in Materialize: https://github.com/Dogfalo/materialize/pull/6339
// Suggested by @burnEAx: https://github.com/Dogfalo/materialize/issues/6336#issuecomment-523409695

$(document).on('click', '.select-wrapper', function (e) { e.stopPropagation(); })
