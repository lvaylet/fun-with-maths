use rand::Rng;
use std::convert::Infallible;
use warp::{http::Response, Filter};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Clone)]
struct Question {
    a: u8,
    b: u8,
    operator: char,
    correct_answer: i8,
    choices: [i8; 4],
}

#[derive(Serialize, Deserialize)]
struct AnswerRequest {
    question: Question,
    answer: i8
}

fn generate_question() -> Question {
    let mut rng = rand::rng();
    let a: u8 = rng.random_range(1..10);
    let b: u8 = rng.random_range(1..10);

    let operator = if rng.random_bool(0.5) { '+' } else { '-' };

    let (first, second) = if operator == '-' && b > a {
        (b, a) // Swap for display purposes if b > a, but keep original for calculation
    } else {
        (a, b) // Keep original order otherwise
    };

    let correct_answer = match operator {
        '+' => a as i8 + b as i8,
        '-' => (first as i8 - second as i8).max(0), // Ensure positive result
        _ => unreachable!(),
    };

    let mut choices = [
        correct_answer,
        (correct_answer as i8 + rng.random_range(1..=3)).max(0), // Ensure positive choices
        (correct_answer as i8 + rng.random_range(-3..=-1)).max(0),
        (correct_answer as i8 + rng.random_range(-2..=2)).max(0),
    ];

    // Ensure all choices are unique
    while choices[1] == choices[0] { choices[1] = (correct_answer as i8 + rng.random_range(1..=3)).max(0); }
    while choices[2] == choices[0] || choices[2] == choices[1] { choices[2] = (correct_answer as i8 + rng.random_range(-3..=-1)).max(0); }
    while choices[3] == choices[0] || choices[3] == choices[1] || choices[3] == choices[2] { choices[3] = (correct_answer as i8 + rng.random_range(-2..=2)).max(0); }

    // Shuffle the choices
    choices.sort_unstable_by_key(|_| rng.random::<u32>());

    Question {
        a: first, // Use swapped numbers for display
        b: second,
        operator,
        correct_answer,
        choices,
    }
}

async fn handle_question() -> Result<impl warp::Reply, Infallible> {
    let question = generate_question();
    Ok(warp::reply::json(&question))
}

async fn handle_answer(
    request: AnswerRequest
) -> Result<impl warp::Reply, Infallible> {
    let correct = request.answer == request.question.correct_answer;
    Ok(warp::reply::json(&correct))
}

#[tokio::main]
async fn main() {
    let question_route = warp::path("question").and(warp::get()).and_then(handle_question);

    let answer_route = warp::path("answer")
        .and(warp::post())
        .and(warp::body::json())
        .and_then(handle_answer);

    let index = warp::path::end().map(|| {
        Response::builder()
            .header("Content-Type", "text/html; charset=utf-8")
            .body(include_str!("index.html")) // Include the HTML file
    });

    let routes = index.or(question_route).or(answer_route);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}
