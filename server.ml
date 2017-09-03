open Graphql_lwt

module List = struct
  include List

  let rec drop t ~n =
    match t with
    | [] -> t
    | _ when n <= 0 -> t
    | _::xs -> drop xs ~n:(n-1)

  let rec take ?(memo=[]) t ~n =
    match t with
    | [] -> List.rev memo
    | _ when n <= 0 -> List.rev memo
    | x::xs -> take ~memo:(x::memo) xs ~n:(n-1)
end

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
      ~args:Arg.[
        arg' "page" ~typ:int ~default:1;
        arg' "per_page" ~typ:int ~default:10;
      ]
      ~resolve:(fun _ () page per_page ->
        let offset = (page-1)*per_page in
        List.drop ~n:offset packages
        |> List.take ~n:per_page
      )
    ;
    field "package"
      ~typ:package
      ~args:Arg.[
        arg ~typ:(non_null string) "name"
      ]
      ~resolve:(fun _ () name ->
        Package.find_by_name packages name
      )
    ;
  ]
)

let () =
  Server.start ~ctx:(fun () -> ()) schema
  |> Lwt_main.run
