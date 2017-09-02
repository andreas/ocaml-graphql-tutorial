(* github_request : token:string ->
 *                  query:string ->
 *                  variables:Yojson.Basic.json ->
 *                  (Yojson.Basic.json,
 *                   [`JSON of string | `HTTP of Cohttp.Response.t * string]
 *                  ) result Lwt.t
 *)
let github_request ~token ~query ~variables =
  let open Lwt.Infix in
  let uri = Uri.of_string "https://api.github.com/graphql" in
  let headers = Cohttp.Header.of_list [
    "Authorization", "bearer " ^ token;
    "User-Agent", "andreas/ppx_graphql";
  ] in
  let body = `Assoc [
    "query", `String query;
    "variables", variables;
  ] in
  let serialized_body = Yojson.Basic.to_string body in
  Cohttp_lwt_unix.Client.post ~headers ~body:(`String serialized_body) uri >>= fun (rsp, body) ->
  Cohttp_lwt_body.to_string body >|= fun body' ->
  match Cohttp.Code.(code_of_status rsp.status |> is_success) with
  | false ->
      Error (`HTTP (rsp, body'))
  | true ->
      try Ok (Yojson.Basic.from_string body') with
      | Yojson.Json_error err ->
          Error (`JSON err)

(* executable_query : (string *
 *                     ((Yojson.Basic.json -> 'a) -> 'a) *
 *                     (Yojson.Basic.json -> 'b)
 *                    ) ->
 *                    token:string -> 'a
 *)
let executable_query (query, kvariables, parse) =
  let open Lwt_result.Infix in
  fun ~token -> (
    kvariables (fun variables ->
      github_request token query variables >|= fun rsp ->
      parse rsp
    )
  )

let find_repo = executable_query [%graphql {|
  query FindRepo($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      stargazers {
        totalCount
      }
      issues(first: 5) {
        nodes {
          title
          body
          url
        }
      }
    }
  }
|}]
