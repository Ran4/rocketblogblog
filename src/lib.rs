#[macro_use] extern crate diesel;
extern crate dotenv;
#[macro_use] extern crate serde_derive;
// extern crate serde_json;

pub mod schema;
pub mod models;

use self::models::{Post, NewPost};

use diesel::prelude::*;
use dotenv::dotenv;
use std::env;

use schema::posts::dsl::posts;

pub fn establish_connection() -> PgConnection {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url))
}

pub fn get_post(post_id: &i32) -> Result<Post, diesel::result::Error> {
    posts.find(*post_id).get_result(&establish_connection())
}

pub fn insert_post_into_db(new_post: &Post) -> Result<Post, diesel::result::Error> {
    let conn = establish_connection();
    diesel::insert_into(schema::posts::table)
        .values(new_post).get_result::<Post>(&conn)
}

pub fn insert_new_post_into_db(new_post: &NewPost) -> Result<Post, diesel::result::Error> {
    let conn = establish_connection();
    diesel::insert_into(schema::posts::table)
        .values(new_post).get_result(&conn)
}
