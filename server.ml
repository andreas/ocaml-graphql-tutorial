open Graphql_lwt

let packages = Package.load_all ()

let schema = Schema.(schema [
    (* Add fields here *)
  ]
)

let () =
  Server.start ~ctx:(fun () -> ()) schema
  |> Lwt_main.run
