#![feature(plugin)]
#![plugin(rocket_codegen)]
extern crate rocket_blog;
extern crate serde;
extern crate serde_json;

extern crate rocket;
extern crate rocket_contrib;

extern crate diesel;

use rocket_contrib::Json;

use rocket_blog::models::{Post, NewPost};

/// Post found -> 200 OK with Post as the JSON body
/// Post not found -> 404 Not Found
/// DB error -> 500 Internal Error
#[get("/post/<post_id>")]
fn read_post(post_id: i32) -> Result<Option<Json<Post>>, diesel::result::Error> {
    match rocket_blog::get_post(&post_id) {
        Ok(post) => Ok(Some(Json(post))),
        Err(diesel::result::Error::NotFound) => Ok(None),
        Err(e) => Err(e),
    }
}

#[post("/post", data = "<input_json>")]
fn create_post(input_json: String) -> Json<Post> {
    let new_post: NewPost = serde_json::from_str(&input_json).unwrap();
    let post: Post = rocket_blog::insert_new_post_into_db(&new_post).unwrap();
    Json(post)
}

fn main() {
    let routes = routes![
        read_post,
        // old_create_post,
        create_post,
    ];
    rocket::ignite().mount("/", routes).launch();
}
