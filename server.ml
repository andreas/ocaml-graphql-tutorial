open Graphql_lwt

let packages = Package.load_all ()

let package = Schema.(obj "Package"
  ~fields:(fun _ -> [
    field "name"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ pkg -> pkg.Package.name)
    ;
    field "version"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ pkg -> pkg.Package.version)
  ])
)

let schema = Schema.(schema [
    field "packageCount"
      ~typ:(non_null int)
      ~args:Arg.[]
      ~resolve:(fun _ () ->
        List.length packages
      )
    ;
    field "packages"
      ~typ:(non_null (list (non_null package)))
      ~args:Arg.[]
      ~resolve:(fun _ () ->
        packages
      )
  ]
)

let () =
  Server.start ~ctx:(fun () -> ()) schema
  |> Lwt_main.run
