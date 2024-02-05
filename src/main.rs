use std::{
    env::args,
    fs::File,
    io::{BufRead, BufReader},
    process
};
use colored::Colorize;
use webbrowser;

fn main() {
    let args: Vec<String> = args().collect();
    let mut no_such_files = Vec::<&str>::new();

    if args.len() < 2 {
        println!(
            "{} - A tool for opening URLs from text files\n\n{}: oorl {}",
            "oorl".bold(),
            "Usage".underline(),
            "path1 path2 path3 ...".green()
        );
        process::exit(1);
    }

    for path in args.iter() {
        if let Ok(file) = File::open(path) {
            for line in BufReader::new(file).lines().filter_map(|line| line.ok()) {
                for url in line
                    .split_whitespace()
                    .filter(|s| s.starts_with("http://") || s.starts_with("https://"))
                {
                    let _ = webbrowser::open(url);
                    println!("{path}: {}", url.yellow());
                }
            }
        } else { no_such_files.push(path); }
    }

    if !no_such_files.is_empty() {
        eprintln!("No such files: {}", no_such_files.join(", ").red());
        process::exit(1);
    }
}