[
  import_deps: [:phoenix, :ecto, :ecto_sql],
  inputs: ["*.{ex,exs}", "{config,lib,priv,test,web}/**/*.{ex,exs}"],
  locals_without_parens: [
    coherence_routes: :*
  ]
]
