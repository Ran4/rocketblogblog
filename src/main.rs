#![feature(plugin)]
#![plugin(rocket_codegen)]
extern crate rocket_blog;
extern crate serde;
extern crate serde_json;

extern crate rocket;
extern crate rocket_contrib;
extern crate rocket_cors;

extern crate diesel;

use rocket_contrib::Json;

use rocket_blog::models::{Post, NewPost};

/// Takes a result coming from a diesel `get_result`/`get_results` and
///     returns a reasonable response.
/// Ok Result          -> 200 OK with the result returned as JSON
/// DB error NotFound  -> 404 Not Found
/// Any other DB error -> 500 Internal Error
fn unwrap_diesel_find<T: serde::ser::Serialize>(db_result: Result<T, diesel::result::Error>)
        -> Result<Option<Json<T>>, diesel::result::Error> {
    match db_result {
        Ok(val) => Ok(Some(Json(val))),
        Err(diesel::result::Error::NotFound) => Ok(None),
        Err(e) => Err(e),
    }
}

/// Post found -> 200 OK with Post as the JSON body
/// Post not found -> 404 Not Found
/// DB error -> 500 Internal Error
#[get("/post/latest")]
fn read_latest_posts() -> Result<Option<Json<Vec<Post>>>, diesel::result::Error> {
    unwrap_diesel_find(rocket_blog::get_latest_posts())
}

/// Post found -> 200 OK with Post as the JSON body
/// Post not found -> 404 Not Found
/// DB error -> 500 Internal Error
#[get("/post/<post_id>")]
fn read_post(post_id: i32) -> Result<Option<Json<Post>>, diesel::result::Error> {
    unwrap_diesel_find(rocket_blog::get_post(&post_id))
}

use rocket::response::status::{BadRequest};

#[post("/post", data = "<new_post>")]
fn create_post(new_post: Json<NewPost>)
        -> Result<Json<Post>, BadRequest<serde_json::Error>> {
    let post: Post = rocket_blog::insert_new_post_into_db(&new_post).unwrap();
    Ok(Json(post))
}

#[delete("/post/<post_id>")]
fn delete_post(post_id: i32)
        -> Result<Option<Json<i32>>, diesel::result::Error> {
    Ok(Some(Json(post_id)))
    // let post: Post = rocket_blog::insert_new_post_into_db(&new_post).unwrap();
    // Ok(Json(post))
}

fn main() {
    let routes = routes![
        read_post,
        delete_post,
        read_latest_posts,
        create_post,
    ];
    
    rocket::ignite()
        .mount("/", routes)
        .attach(rocket_cors::Cors::default())
        .launch();
}
