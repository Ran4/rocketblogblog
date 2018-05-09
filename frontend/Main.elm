import Json.Encode exposing (encode, string, int, float, bool,list, object)
import Json.Decode as Decode

import Http

import Html exposing (Html, button, input, div, text)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, value, style)

-- Types
--------------------------------------------------------------------

type alias PostId = Int

type alias Post =
    { id : PostId
    , number : Int
    }
    
type alias Model =
    { numberField : String
    , idToFetch : Int
    , newPost : Result String Json.Encode.Value
    , posts : List Post
    , status : String
    }

type Action
    = NoOp
    | Send Json.Encode.Value
    | SendResult (Result Http.Error Post)
    | FetchAll
    | FetchAllResult (Result Http.Error (List Post))
    | DeletePost PostId
    | DeletePostResult (Result Http.Error PostId)
    | UpdateNumber String
    
examplePost : Post
examplePost =
    { id = 0
    , number = 999
    }
    
initialModel : Model
initialModel =
    { numberField = "993"
    , idToFetch = 28
    , newPost = Err ""
    , posts = []
    , status = "No status"
    }
    
-- JSON decoding/encoding
--------------------------------------------------------------------
newPostJson : String -> Result String Json.Encode.Value
newPostJson numberField =
    case String.toInt numberField of
        Ok number ->
            object
                [ ("number", int number)
                ]
            |> Ok
        Err e ->
            Err e
                
postDecoder : Decode.Decoder Post
postDecoder =
    Decode.map2
        Post
        (Decode.field "id" Decode.int)
        (Decode.field "number" Decode.int)
        
postsDecoder : Decode.Decoder (List Post)
postsDecoder =
    Decode.list postDecoder
    
    
-- Update
--------------------------------------------------------------------

baseUrl : String
baseUrl = "http://localhost:8000"

get : String -> Decode.Decoder a -> Http.Request a
get subUrl =
    Http.get (baseUrl ++ subUrl)
    
post : String -> Http.Body -> Decode.Decoder a -> Http.Request a
post subUrl =
    Http.post (baseUrl ++ subUrl)
        
delete : String -> Http.Body -> Decode.Decoder a -> Http.Request a
delete subUrl body jsonDecoder =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = (baseUrl ++ subUrl)
        , body = body
        , expect = Http.expectJson jsonDecoder
        , timeout = Nothing
        , withCredentials = False
        }
            
getLatestPosts : Http.Request (List Post)
getLatestPosts =
    get "/post/latest" postsDecoder
    
deletePost : PostId -> Http.Request PostId
deletePost postId =
    delete
        ("/post/" ++ toString postId)
        Http.emptyBody
        (Decode.int |> Decode.map (\x -> x))
    
sendPost : Json.Encode.Value -> Http.Request Post
sendPost postJson =
    post "/post/" (Http.jsonBody postJson) postDecoder

update : Action -> Model -> ( Model , Cmd Action )
update msg model = 
    case msg of
        NoOp ->
            (model, Cmd.none)
        FetchAll ->
            ( { model | status = "Fetching posts..."}
            , Http.send FetchAllResult getLatestPosts)
        FetchAllResult (Ok posts) ->
            ({ model | posts = posts
                     , status = let numPosts = toString <| List.length posts
                                in "Fetched " ++ numPosts ++ " posts"
             }
             , Cmd.none)
        FetchAllResult (Err e) ->
            ({ model | posts = [], status = "Problem fetching" }, Cmd.none)
        Send newPost ->
            (model, Http.send SendResult (sendPost newPost))
        SendResult (Ok post) ->
            update FetchAll { model | status = toString post}
        SendResult (Err e) ->
            ({ model | status = toString e}, Cmd.none)
        DeletePost postId ->
            (model, Http.send DeletePostResult (deletePost postId))
        DeletePostResult (Ok deletedPostId) ->
            let newStatus = "Deleted post with id " ++ toString deletedPostId
            in { model | status = newStatus}
               |> update FetchAll
        DeletePostResult (Err e) ->
            let newStatus = "Error when deleting post: " ++ toString e
            in ({ model | status = newStatus }, Cmd.none)
        UpdateNumber s ->
            ({ model | numberField = s, newPost = newPostJson s}, Cmd.none)
            
            
        
-- Views
--------------------------------------------------------------------

-- Styling

bigButton : List ( String , String )
bigButton = 
    [ ("height", "30px")
    , ("width", "100px")
    ]
    
-- "Components"
            
fetchPostView : Model -> Html Action
fetchPostView model =
    div []
        [button [ style bigButton
                , value (toString model.idToFetch)
                , onClick FetchAll ]
                [ if List.length model.posts == 0
                    then text "Fetch posts"
                    else text "Fetch posts again"
                ]
        ]
        
        
viewPost : Post -> Html Action
viewPost post =
    div []
        [ button [ style [ ("color", "red")
                         , ("padding", "2px")
                         , ("margin", "4px")
                         ]
                 , onClick (DeletePost post.id)
                 ] [ text "Delete" ]
        , text <| "Id: " ++ toString post.id ++ ", Number: " ++ toString post.number]
        
fetchedPostsView : Model -> Html Action
fetchedPostsView model =
    div [ style [ ("border-style", "dotted")
                , ("padding", "4px")
                ]]
        [ div [ style [("font-weight", "bold")]] [text "Posts:"]
        , div [] (List.map viewPost model.posts)
        , fetchPostView model
        ]
            
newPostView : Model -> Html Action
newPostView model =
    div [ style [ ("border-style", "dotted")
                , ("padding", "4px")
                ]]
        [ div [ style [ ("font-weight", "bold")
                      , ("padding", "6px")
                      ]
              ]
              [text "New post:"]
        , text "Number:"
        , input [ value model.numberField, placeholder "42", onInput UpdateNumber ] []
        , div [] (
            case model.newPost of
                Ok value ->
                    [ text <| "Will send: " ++ encode 4 value
                    , div [] [button [ style (("margin", "6px") :: bigButton)
                                     , onClick (Send value) ] [ text "Send!"]]]
                Err e ->
                    [ text <| if String.length model.numberField > 0
                              then e
                              else "Waiting for input..."
                    ]
        )]
            
view : Model -> Html Action
view model =
    div []
        [ fetchedPostsView model
        , newPostView model
        , text <| "Status: " ++ model.status
        ]
    
main : Program Never Model Action
main = Html.program
    { init = update FetchAll initialModel 
    , view = view
    , subscriptions = always Sub.none
    , update = update
    }
