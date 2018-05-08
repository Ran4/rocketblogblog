use super::schema::posts;

#[derive(Serialize, Deserialize, Debug)]
#[derive(Insertable, Queryable)]
#[table_name="posts"]
pub struct Post {
    id: i32,
    number: i32,
}

#[derive(Deserialize, Debug)]
#[derive(Insertable)]
#[table_name="posts"]
pub struct NewPost {
    number: i32,
}
