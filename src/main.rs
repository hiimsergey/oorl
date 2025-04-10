use colored::Colorize;
use std::{
    env, fmt,
    fs::File,
    io::{BufRead, BufReader},
    process,
};
use webbrowser;

fn main() {
    let mut args_iter = env::args();
    args_iter.next(); // removes argument "oorl"
    let args: Vec<String> = args_iter.collect();
    let mut no_such_files = Vec::<&str>::new();

    if args.is_empty() {
        println!(
            "{} - A tool for opening URLs from text files
v0.1.4

{}:\toorl {}
\t\t{}
\toorl -s {}
\t\t{}
\toorl -l {}",
            "oorl".bold(),
            "Usage".underline(),
            "path1 path2 path3 ...".green(),
            "or".italic(),
            "\"string containing URLs\"".yellow(),
            "or".italic(),
            "path".green()
        );
        process::exit(1);
    }

    if args[0] == "-l" || args[0] == "--last" {
        if args.len() != 2 {
            eprintln!("oorl: Usage: oorl -l <path>");
            process::exit(1);
        } else {
            if let Ok(file) = File::open(&args[1]) {
                let lines: Vec<String> = BufReader::new(file)
                    .lines()
                    .filter_map(Result::ok)
                    .collect();

                for line in lines.iter().rev() {
                    if open_urls_from_line(&line, &args[1]) { process::exit(0); }
                }
            } else {
                eprintln!("oorl: no such file: {}", &args[1]);
                process::exit(1);
            }
        }
        process::exit(0);
    }

    if args[0] == "-s" || args[0] == "--string" {
        if args.len() == 1 {
            eprintln!("oorl: input string missing!");
            process::exit(1);
        } else {
            open_urls_from_line(&args[1], &"string".green());
        }
        process::exit(0);
    }

    for path in args.iter() {
        if let Ok(file) = File::open(path) {
            for line in BufReader::new(file).lines().filter_map(|line| line.ok()) {
                open_urls_from_line(&line, &path);
            }
        } else {
            no_such_files.push(path);
        }
    }

    if !no_such_files.is_empty() {
        eprintln!("oorl: no such files: {}", no_such_files.join(", ").red());
        process::exit(1);
    }
}

/// Opens every valid URL it can find in a given string slice line
fn open_urls_from_line(line: &str, path: impl fmt::Display) -> bool {
    for word in line.split_whitespace() {
        if webbrowser::open(
            // Removes possible backslashes, e.g. occuring in LaTeX source files
            word.chars()
                .filter(|c| *c != '\\')
                .collect::<String>()
                .as_str(),
        ).is_ok() {
            println!("{path}: {}", word.yellow());
            return true;
        }
    }

    return false;
}
