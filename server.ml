open Lwt.Infix
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

type app_context = {
  github_token : string;
}

let packages = Package.load_all ()

let github_issue = Schema.(obj "GithubIssue"
  ~fields:(fun issue -> [
    field "title"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ issue -> issue#title)
    ;
    field "body"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ issue -> issue#body)
    ;
    field "url"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ issue -> issue#url)
    ;
  ])
)

let github_repo = Schema.(obj "GithubRepo"
  ~fields:(fun repo -> [
    field "stars"
      ~typ:(non_null int)
      ~args:Arg.[]
      ~resolve:(fun _ repo -> repo#stargazers#totalCount)
    ;
    field "issues"
      ~typ:(list github_issue)
      ~args:Arg.[]
      ~resolve:(fun _ repo -> repo#issues#nodes)
    ;
  ])
)

let relop = Schema.(enum "Relop"
  ~values:[
    enum_value "EQ" ~value:`Eq;
    enum_value "NEQ" ~value:`Neq;
    enum_value "LT" ~value:`Lt;
    enum_value "LEQ" ~value:`Leq;
    enum_value "GT" ~value:`Gt;
    enum_value "GEQ" ~value:`Geq;
  ]
)

let version_constraint = Schema.(obj "VersionConstraint"
  ~fields:(fun _ -> [
    field "version"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ (_, version) -> version)
    ;
    field "relop"
      ~typ:(non_null relop)
      ~args:Arg.[]
      ~resolve:(fun _ (relop, _) -> relop)
  ])
)

let rec dependency = lazy Schema.(obj "Dependency"
  ~fields:(fun _ -> [
    field "name"
      ~typ:(non_null string)
      ~args:Arg.[]
      ~resolve:(fun _ (name, _) -> name)
    ;
    field "package"
      ~typ:Lazy.(force package)
      ~args:Arg.[]
      ~resolve:(fun _ (name, _) -> Package.find_by_name packages name)
    ;
    field "version_constraint"
      ~typ:version_constraint
      ~args:Arg.[]
      ~resolve:(fun _ (_, version_constraint) -> version_constraint)
  ])
)
and package = lazy Schema.(obj "Package"
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
    ;
    field "dependencies"
      ~typ:(non_null (list (non_null Lazy.(force dependency))))
      ~args:Arg.[]
      ~resolve:(fun _ pkg -> pkg.Package.dependencies)
    ;
    field "git_repo"
      ~typ:string
      ~args:Arg.[]
      ~resolve:(fun _ pkg -> pkg.Package.git_repo)
    ;
    io_field "github"
      ~typ:github_repo
      ~args:Arg.[]
      ~resolve:(fun ctx pkg ->
        match Package.github_owner_and_name pkg with
        | None -> Lwt.return None
        | Some (owner, name) ->
            Github.find_repo ~token:ctx.github_token ~owner ~name () >|= function
            | Ok rsp -> rsp#repository
            | Error _ -> None
      )
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
      ~typ:(non_null (list (non_null Lazy.(force package))))
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
      ~typ:Lazy.(force package)
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
  let github_token = Unix.getenv "GITHUB_TOKEN" in
  Server.start ~ctx:(fun () -> { github_token }) schema
  |> Lwt_main.run
